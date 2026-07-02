import { useParams } from 'react-router-dom';

export default function Ticket() {
  const { token } = useParams<{ token: string }>();

  return (
    <section>
      <h1>Ticket: {token}</h1>
      <p>Acá se va a mostrar el estado del turno y la opción de descargar PDF.</p>
    </section>
  );
}
