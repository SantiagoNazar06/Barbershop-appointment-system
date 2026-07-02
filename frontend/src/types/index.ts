export interface BarberShop {
  id: number;
  nombre: string;
  slug: string;
  direccion: string;
  telefono: string;
}

export interface Turno {
  id: number;
  nombreCliente: string;
  dniCliente: string;
  horario: string;
  estado: 'RESERVADO' | 'ATENDIDO' | 'AUSENTE' | 'CANCELADO';
  precioCobrado: number | null;
  tokenTicket: string;
}

export interface Ticket {
  id: number;
  nombreCliente: string;
  horario: string;
  estado: string;
  ticketPdfDisponible: boolean;
  ticketPdfUrl: string | null;
}
