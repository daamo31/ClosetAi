// src/services/outfits.ts
import { API_URL, getAuthHeader } from '../config/api';
import type { Outfit } from '../types';

export async function generateOutfit(params: {
  city?: string;
  lat?: number;
  lon?: number;
  occasion: string;
}): Promise<Outfit> {
  const headers = await getAuthHeader();
  const query = new URLSearchParams({ occasion: params.occasion });
  if (params.city) query.set('city', params.city);
  if (params.lat !== undefined) query.set('lat', String(params.lat));
  if (params.lon !== undefined) query.set('lon', String(params.lon));

  const res = await fetch(`${API_URL}/api/outfits/generate?${query}`, { headers });
  if (!res.ok) throw new Error((await res.json()).detail ?? 'Error al generar outfit');
  return res.json();
}
