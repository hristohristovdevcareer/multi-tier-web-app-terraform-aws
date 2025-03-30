import Header from "@/components/header/header";
import Content from "@/components/content/content";

export default function Home() {

  return (
    <section className="flex flex-col py-20">
      <Header title="Hello Everyone!" description="This is a description of the application" />
      <Content />
    </section>
  );
}
