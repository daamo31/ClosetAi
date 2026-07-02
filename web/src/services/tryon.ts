// src/services/tryon.ts
import { API_URL, getAuthHeader } from '../config/api';

export async function virtualTryOn(
  personImage: File,
  garmentIds: string[],   // array de UUIDs — outfit completo
): Promise<{ result_url: string; garments: string[]; total_steps: number }> {
  const headers = await getAuthHeader();
  const form = new FormData();
  form.append('person_image', personImage);
  form.append('garment_ids', JSON.stringify(garmentIds));

  const res = await fetch(`${API_URL}/api/tryon`, {
    method: 'POST',
    headers,
    body: form,
  });

  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.detail ?? 'Error en el probador virtual');
  }
  return res.json();
}
