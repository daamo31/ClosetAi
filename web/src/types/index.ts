// src/types/index.ts
export interface Garment {
  id: string;
  user_id: string;
  name: string;
  category: 'top' | 'bottom' | 'shoes' | 'outerwear' | 'accessory';
  color: string;
  season: 'spring' | 'summer' | 'autumn' | 'winter' | 'all';
  occasion: 'work' | 'casual' | 'sport' | 'formal';
  purchase_price: number;
  image_url: string | null;
  times_used: number;
  cost_per_wear: number;
  created_at: string;
}

export interface GarmentListResponse {
  garments: Garment[];
  total: number;
  free_limit: number;
  can_add_more: boolean;
}

export interface WeatherInfo {
  city: string;
  temperature: number;
  feels_like: number;
  description: string;
  humidity: number;
  wind_speed: number;
}

export interface Outfit {
  id: string;
  user_id: string;
  occasion: string;
  weather: WeatherInfo | null;
  ai_reasoning: string | null;
  garments: Garment[];
  created_at: string;
}

export type Screen = 'dashboard' | 'wardrobe' | 'upload' | 'outfit';
