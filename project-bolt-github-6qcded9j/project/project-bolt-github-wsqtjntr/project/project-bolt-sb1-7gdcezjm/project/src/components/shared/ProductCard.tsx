import { Link } from 'react-router-dom';
import { Heart, Scan } from 'lucide-react';
import { Badge } from '@/components/ui';
import { RatingStars } from './RatingStars';
import { useWishlist } from '@/context';
import { formatMoney, cx } from '@/lib/utils';
import type { Product } from '@/types';

export interface ProductCardProps {
  product: Product;
}

export function ProductCard({ product }: ProductCardProps) {
  const { has, toggle } = useWishlist();
  const isWishlisted = has(product.id);
  const primaryImage = product.images[0];
  const hoverImage = product.images[1] ?? product.images[0];
  const onSale =
    product.compareAtPriceCents !== null &&
    product.compareAtPriceCents < product.priceCents;

  return (
    <div className="group relative flex flex-col">
      <Link to={`/product/${product.slug}`} className="block overflow-hidden rounded-2xl bg-ink-100">
        <div className="relative aspect-square overflow-hidden">
          <img
            src={primaryImage.url}
            alt={primaryImage.altText ?? product.name}
            loading="lazy"
            className="absolute inset-0 h-full w-full object-cover transition-all duration-500 ease-[var(--ease-emphasized)] group-hover:scale-105 group-hover:opacity-0"
          />
          <img
            src={hoverImage.url}
            alt={hoverImage.altText ?? product.name}
            loading="lazy"
            className="absolute inset-0 h-full w-full object-cover opacity-0 transition-all duration-500 ease-[var(--ease-emphasized)] group-hover:scale-105 group-hover:opacity-100"
          />
          {onSale && (
            <Badge variant="error" className="absolute left-3 top-3 z-10">
              Sale
            </Badge>
          )}
        </div>
      </Link>

      {/* Wishlist button */}
      <button
        type="button"
        onClick={() => toggle(product.id)}
        aria-label={isWishlisted ? 'Remove from wishlist' : 'Add to wishlist'}
        aria-pressed={isWishlisted}
        className={cx(
          'absolute right-3 top-3 z-10 flex h-9 w-9 items-center justify-center rounded-full backdrop-blur-md transition-all duration-200',
          'bg-white/80 hover:bg-white',
          isWishlisted ? 'text-error-500' : 'text-ink-600 hover:text-ink-900',
        )}
      >
        <Heart size={18} className={cx(isWishlisted && 'fill-error-500')} />
      </button>

      {/* Try On placeholder */}
      <button
        type="button"
        onClick={(e) => e.preventDefault()}
        className={cx(
          'absolute bottom-3 left-1/2 z-10 flex -translate-x-1/2 translate-y-4 items-center gap-1.5 rounded-full bg-ink-900/90 px-4 py-2 text-xs font-medium text-white backdrop-blur-md',
          'opacity-0 transition-all duration-300 ease-[var(--ease-emphasized)] group-hover:translate-y-0 group-hover:opacity-100',
        )}
      >
        <Scan size={14} />
        Try On
      </button>

      {/* Info */}
      <div className="mt-3 flex flex-col gap-1">
        <div className="flex items-center justify-between">
          <span className="text-xs font-medium uppercase tracking-wide text-ink-500">
            {product.brandName ?? 'Vuera'}
          </span>
          <RatingStars rating={product.rating ?? 0} size={12} />
        </div>
        <Link to={`/product/${product.slug}`}>
          <h3 className="text-base font-semibold text-ink-900 transition-colors hover:text-primary-700">
            {product.name}
          </h3>
        </Link>
        <div className="flex items-center gap-2">
          <span className="text-base font-semibold text-ink-900">
            {formatMoney(product.priceCents)}
          </span>
          {onSale && (
            <span className="text-sm text-ink-400 line-through">
              {formatMoney(product.compareAtPriceCents!)}
            </span>
          )}
        </div>
      </div>
    </div>
  );
}
