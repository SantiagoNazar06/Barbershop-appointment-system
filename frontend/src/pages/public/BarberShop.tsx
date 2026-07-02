import { useParams } from 'react-router-dom';

export default function BarberShop() {
  const { slug } = useParams<{ slug: string }>();

  return (
    <section>
      <h1>Barbería: {slug}</h1>
      <p>Acá se va a mostrar la info pública y el selector de turnos.</p>
    </section>
  );
}
