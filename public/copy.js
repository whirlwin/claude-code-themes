// Copy buttons for the commands. Without JavaScript the buttons stay hidden,
// and the commands can still be selected and copied by hand.
const status = document.getElementById('copy-status')

for (const button of document.querySelectorAll('button.copy')) {
  const label = button.querySelector('.copy__label')
  const code = button.parentElement.querySelector('code')
  let timer
  button.hidden = false
  button.addEventListener('click', async () => {
    try {
      await navigator.clipboard.writeText(code.textContent)
      label.textContent = 'copied'
      status.textContent = `Copied: ${code.textContent}`
    } catch {
      // No clipboard access, so select the command for the keyboard shortcut.
      getSelection().selectAllChildren(code)
      label.textContent = 'selected'
      status.textContent = 'Selected the command. Press Cmd+C or Ctrl+C to copy it.'
    }
    clearTimeout(timer)
    timer = setTimeout(() => { label.textContent = 'copy' }, 2000)
  })
}
