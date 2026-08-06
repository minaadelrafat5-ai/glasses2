import { Link } from 'react-router-dom';
import { Button } from '@/components/ui';

export function NotFoundPage() {
  return (
    <div className="container-app py-24 md:py-32">
      <div className="mx-auto max-w-md text-center">
        <p className="text-7xl font-semibold text-primary-600">404</p>
        <h1 className="mt-4 text-2xl font-semibold">Page not found</h1>
        <p className="mt-3 text-ink-500">
          The page you're looking for doesn't exist or has moved.
        </p>
        <Link to="/" className="mt-8 inline-block">
          <Button>Back to home</Button>
        </Link>
      </div>
    </div>
  );
}
