import { createBrowserRouter, type RouteObject } from 'react-router-dom';
import { RootLayout } from '@/components/layout';
import { AdminRoute } from '@/components/shared';
import {
  HomePage,
  ShopPage,
  ProductDetailPage,
  CartPage,
  TryOnPage,
  AssistantPage,
  AccountPage,
  SearchPage,
  AboutPage,
  ContactPage,
  NotFoundPage,
  AdminDashboardPage,
  AdminProductsPage,
  AdminProductFormPage,
  AdminOrdersPage,
  AdminOrderDetailPage,
  AdminCustomersPage,
  AdminCustomerDetailPage,
  AdminAttributesPage,
} from '@/pages';

export const routes: RouteObject[] = [
  {
    path: '/',
    element: <RootLayout />,
    children: [
      { index: true, element: <HomePage /> },
      { path: 'shop', element: <ShopPage /> },
      { path: 'shop/:categorySlug', element: <ShopPage /> },
      { path: 'product/:slug', element: <ProductDetailPage /> },
      { path: 'cart', element: <CartPage /> },
      { path: 'try-on', element: <TryOnPage /> },
      { path: 'assistant', element: <AssistantPage /> },
      { path: 'account', element: <AccountPage /> },
      { path: 'search', element: <SearchPage /> },
      { path: 'about', element: <AboutPage /> },
      { path: 'contact', element: <ContactPage /> },
      { path: '*', element: <NotFoundPage /> },
    ],
  },
  {
    path: '/admin',
    element: <AdminRoute><AdminDashboardPage /></AdminRoute>,
  },
  {
    path: '/admin/products',
    element: <AdminRoute><AdminProductsPage /></AdminRoute>,
  },
  {
    path: '/admin/products/new',
    element: <AdminRoute><AdminProductFormPage /></AdminRoute>,
  },
  {
    path: '/admin/products/:slug',
    element: <AdminRoute><AdminProductFormPage /></AdminRoute>,
  },
  {
    path: '/admin/orders',
    element: <AdminRoute><AdminOrdersPage /></AdminRoute>,
  },
  {
    path: '/admin/orders/:orderId',
    element: <AdminRoute><AdminOrderDetailPage /></AdminRoute>,
  },
  {
    path: '/admin/customers',
    element: <AdminRoute><AdminCustomersPage /></AdminRoute>,
  },
  {
    path: '/admin/customers/:customerId',
    element: <AdminRoute><AdminCustomerDetailPage /></AdminRoute>,
  },
  {
    path: '/admin/attributes',
    element: <AdminRoute><AdminAttributesPage /></AdminRoute>,
  },
];

export const router = createBrowserRouter(routes);
