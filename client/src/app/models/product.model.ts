/**
 * Shape of a product row as returned by the Express/PostgreSQL API
 * (GET /api/products, GET /api/products/:id).
 */
export interface Product {
  id: number;
  name: string;
  description: string | null;
  price: number;
  quantity: number;
  created_at?: string;
  updated_at?: string;
}

/**
 * Fields the client sends when creating (POST) or updating (PUT) a product.
 * The server owns id / created_at / updated_at.
 */
export interface ProductPayload {
  name: string;
  description: string | null;
  price: number;
  quantity: number;
}
