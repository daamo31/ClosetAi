// src/services/garments.ts
import { API_URL, getAuthHeader } from '../config/api';
import type { Garment, GarmentListResponse } from '../types';

export async function listGarments(): Promise<GarmentListResponse> {
  const headers = await getAuthHeader();
  const res = await fetch(`${API_URL}/api/garments/`, { headers });
  if (!res.ok) throw new Error((await res.json()).detail ?? 'Error al cargar prendas');
  return res.json();
}

export async function uploadGarment(
  image: File,
  meta: {
    name: string;
    category: string;
    color: string;
    season: string;
    occasion: string;
    purchase_price: number;
  }
): Promise<Garment> {
  const headers = await getAuthHeader();
  const form = new FormData();
  form.append('image', image);
  form.append('name', meta.name);
  form.append('category', meta.category);
  form.append('color', meta.color);
  form.append('season', meta.season);
  form.append('occasion', meta.occasion);
  form.append('purchase_price', String(meta.purchase_price));

  const res = await fetch(`${API_URL}/api/garments/upload`, {
    method: 'POST',
    headers, // No poner Content-Type: deja que el navegador lo ponga con el boundary correcto
    body: form,
  });
  if (!res.ok) throw new Error((await res.json()).detail ?? 'Error al subir prenda');
  return res.json();
}

export async function deleteGarment(id: string): Promise<void> {
  const headers = await getAuthHeader();
  const res = await fetch(`${API_URL}/api/garments/${id}`, {
    method: 'DELETE',
    headers,
  });
  if (!res.ok) throw new Error((await res.json()).detail ?? 'Error al eliminar prenda');
}

export async function logUsage(garment_id: string): Promise<void> {
  const headers = await getAuthHeader();
  const res = await fetch(`${API_URL}/api/usage/log`, {
    method: 'POST',
    headers: { ...headers, 'Content-Type': 'application/json' },
    body: JSON.stringify({ garment_id }),
  });
  if (!res.ok) throw new Error((await res.json()).detail ?? 'Error al registrar uso');
}
