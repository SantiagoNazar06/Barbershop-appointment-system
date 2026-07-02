import { Outlet } from 'react-router-dom';

export default function AdminLayout() {
  // TODO: Verificar autenticación — si no hay token, redirigir a /admin/login
  return (
    <main>
      <Outlet />
    </main>
  );
}
