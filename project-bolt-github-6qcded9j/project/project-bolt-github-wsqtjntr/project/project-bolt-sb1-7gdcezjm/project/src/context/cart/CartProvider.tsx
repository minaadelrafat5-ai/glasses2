import { useCallback, useEffect, useMemo, useState } from 'react';
import type { Cart, CartItem } from '@/types';
import { CartContext, type CartContextValue } from './CartContext';

const STORAGE_KEY = 'vuera.cart';
const CURRENCY = 'USD';

interface CartProviderProps {
  children: React.ReactNode;
}

function loadInitial(): CartItem[] {
  if (typeof window === 'undefined') return [];
  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);
    return raw ? (JSON.parse(raw) as CartItem[]) : [];
  } catch {
    return [];
  }
}

export function CartProvider({ children }: CartProviderProps) {
  const [items, setItems] = useState<CartItem[]>(loadInitial);

  useEffect(() => {
    if (typeof window === 'undefined') return;
    try {
      window.localStorage.setItem(STORAGE_KEY, JSON.stringify(items));
    } catch {
      // Storage may be full or disabled — non-fatal.
    }
  }, [items]);

  const addItem = useCallback((item: CartItem) => {
    setItems((prev) => {
      const existing = prev.find((i) => i.variantId === item.variantId);
      if (existing) {
        return prev.map((i) =>
          i.variantId === item.variantId
            ? { ...i, quantity: i.quantity + item.quantity }
            : i,
        );
      }
      return [...prev, item];
    });
  }, []);

  const updateQuantity = useCallback((variantId: string, quantity: number) => {
    setItems((prev) =>
      prev
        .map((i) => (i.variantId === variantId ? { ...i, quantity } : i))
        .filter((i) => i.quantity > 0),
    );
  }, []);

  const removeItem = useCallback((variantId: string) => {
    setItems((prev) => prev.filter((i) => i.variantId !== variantId));
  }, []);

  const clear = useCallback(() => setItems([]), []);

  const subtotalCents = useMemo(
    () => items.reduce((sum, i) => sum + i.unitPriceCents * i.quantity, 0),
    [items],
  );
  const count = useMemo(() => items.reduce((sum, i) => sum + i.quantity, 0), [items]);

  const cart: Cart = useMemo(
    () => ({ items, subtotalCents, currency: CURRENCY }),
    [items, subtotalCents],
  );

  const value = useMemo<CartContextValue>(
    () => ({ items, subtotalCents, count, addItem, updateQuantity, removeItem, clear, cart }),
    [items, subtotalCents, count, addItem, updateQuantity, removeItem, clear, cart],
  );

  return <CartContext.Provider value={value}>{children}</CartContext.Provider>;
}
