import Dialog from '@stimulus-components/dialog'

// Export dialog is mounted globally in layout, but some pages do not render
// an export dialog target. Guard target-dependent calls to avoid runtime errors.
export default class extends Dialog {
  open() {
    if (!this.hasDialogTarget) return

    super.open()
  }

  close() {
    if (!this.hasDialogTarget) return

    super.close()
  }

  backdropClose(event) {
    if (!this.hasDialogTarget) return

    super.backdropClose(event)
  }

  forceClose() {
    if (!this.hasDialogTarget) return

    this.dialogTarget.close()
  }
}
