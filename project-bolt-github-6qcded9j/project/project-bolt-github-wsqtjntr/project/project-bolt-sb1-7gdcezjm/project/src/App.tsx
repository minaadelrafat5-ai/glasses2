import { RouterProvider } from 'react-router-dom';
import { router } from '@/router';
import { AuthProvider, CartProvider, WishlistProvider } from '@/context';

export default function App() {
  return (
    <AuthProvider>
      <WishlistProvider>
        <CartProvider>
          <RouterProvider router={router} />
        </CartProvider>
      </WishlistProvider>
    </AuthProvider>
  );
}
