const banner = document.getElementById('banner');
const bannerText = document.getElementById('bannerText');

let hideTimer = null;

function showBanner(text, mode, durationMs) {
  if (hideTimer) clearTimeout(hideTimer);

  banner.classList.remove('hidden', 'on', 'off', 'show');
  banner.classList.add(mode === 'on' ? 'on' : 'off');

  bannerText.textContent = text || '';

  // force reflow so transition always triggers
  void banner.offsetWidth;

  banner.classList.add('show');

  hideTimer = setTimeout(() => {
    banner.classList.remove('show');
    hideTimer = setTimeout(() => {
      banner.classList.add('hidden');
    }, 240);
  }, Math.max(500, durationMs || 3500));
}

window.addEventListener('message', (event) => {
  const data = event.data;
  if (!data || data.action !== 'show') return;

  showBanner(data.text, data.mode, data.durationMs);
});
