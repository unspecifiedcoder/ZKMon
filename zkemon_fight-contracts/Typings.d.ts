declare module 'zokrates-js/node' {
    function initialize(): Promise<ZoKratesProvider>;
    export { initialize };
  }
  