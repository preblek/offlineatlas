// Runs inside the compressed export's async bootstrap, before atlas.js.
// Blob and Response operate on embedded bytes; there is no fetch or network IO.
if (typeof DecompressionStream !== 'function') {
  const error = new Error('Your browser cannot open this compressed atlas. Open it in a current browser, or ask the author for an uncompressed HTML export (compress = FALSE).');
  error.atlasUnsupported = true;
  throw error;
}
const payloadElement = document.getElementById('atlas-data');
const compressedBytes = Uint8Array.from(atob(payloadElement.textContent.trim()), c => c.charCodeAt(0));
const payloadStream = new Blob([compressedBytes]).stream().pipeThrough(new DecompressionStream('gzip'));
payloadElement.textContent = await new Response(payloadStream).text();
payloadElement.type = 'application/json';
payloadElement.removeAttribute('data-encoding');
document.getElementById('atlas-load-status').remove();
