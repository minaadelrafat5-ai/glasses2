import { PagePlaceholder } from '@/components/shared';

export function TryOnPage() {
  return (
    <PagePlaceholder
      badge="AR & AI"
      title="Virtual Try-On"
      description="Live AR try-on and AI-generated try-on imagery will land here. The AI service layer and feature flags are already in place — enabling them only requires turning on the flag and deploying the edge function."
    />
  );
}
