import Header from "@/components/header/header";
import Content from "@/components/content/content";

export default function Home() {

  return (
    <section className="flex flex-col py-20">
      <Header title="Hello Everyone!" description="This is a great first devops project! I promise..." />
      <div className="w-full max-w-[1024px] mx-auto mb-10">
        <hr></hr>
      </div>
      <Content />
    </section>
  );
}
