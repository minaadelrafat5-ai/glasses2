/**
 * Centralized feature flags. Toggle upcoming capabilities without touching
 * component code. AI features default off until their pipelines ship.
 */
export const featureFlags = {
  virtualTryOn: false,
  aiTryOnImages: false,
  recommendationAssistant: false,
  reviews: true,
  wishlist: true,
} as const;

export type FeatureFlag = keyof typeof featureFlags;
