// src/services/tryon.ts
import { API_URL, getAuthHeader } from '../config/api';

export async function virtualTryOn(
  personImage: File,
  garmentId: string,
): Promise<{ result_url: string; garment: string }> {
  const headers = await getAuthHeader();
  const form = new FormData();
  form.append('person_image', personImage);
  form.append('garment_id', garmentId);

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
