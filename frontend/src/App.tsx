import { BrowserRouter, Route, Routes, Navigate } from 'react-router-dom';
import PublicLayout from './layouts/PublicLayout';
import AdminLayout from './layouts/AdminLayout';
import BarberShop from './pages/public/BarberShop';
import Ticket from './pages/public/Ticket';
import Login from './pages/admin/Login';
import Agenda from './pages/admin/Agenda';

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        {/* Rutas públicas */}
        <Route element={<PublicLayout />}>
          <Route path="/b/:slug" element={<BarberShop />} />
          <Route path="/ticket/:token" element={<Ticket />} />
        </Route>

        {/* Rutas privadas (admin) */}
        <Route path="/admin" element={<AdminLayout />}>
          <Route index element={<Navigate to="/admin/agenda" replace />} />
          <Route path="login" element={<Login />} />
          <Route path="agenda" element={<Agenda />} />
        </Route>

        {/* Redirección por defecto */}
        <Route path="*" element={<Navigate to="/admin/agenda" replace />} />
      </Routes>
    </BrowserRouter>
  );
}
