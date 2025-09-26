export default function TutorialSpace() {
  return (
    <div
      style={{
        position: 'relative',
        width: '100%',
        paddingTop: '40%',
        paddingBottom: '5%',
        height: 0,
        overflow: 'hidden',
      }}
    >
      <iframe
        src="https://demo.arcade.software/zVYe3x4PkZjUkMEMP9Kg?embed&embed_mobile=tab&embed_desktop=inline&show_copy_link=true"
        title="Arcade embed"
        frameBorder="0"
        loading="lazy"
        allow="clipboard-write"
        style={{
          position: 'absolute',
          top: 0,
          left: 0,
          width: '100%',
          height: '100%',
          border: 0,
          colorScheme: 'light',
        }}
      />
    </div>
  );
}