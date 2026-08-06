export { fetchProducts, fetchProductBySlug, fetchCategories, fetchBrands, fetchColors, fetchFrameShapes, fetchMaterials, fetchSizes } from './productService';
export type { ProductQuery, ProductListResult } from './productService';

export { fetchUserOrders, fetchOrderById, orderStatusToLabel } from './orderService';

export { requestVirtualTryOn, requestRecommendations } from './aiService';
