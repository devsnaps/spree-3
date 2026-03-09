import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['permissionCheckbox']

  toggleRow(event) {
    event.preventDefault()

    const subjectClass = event.params.subject
    const rowCheckboxes = this.permissionCheckboxTargets.filter((checkbox) => checkbox.dataset.subjectClass === subjectClass)

    if (rowCheckboxes.length === 0) return

    const shouldCheck = rowCheckboxes.some((checkbox) => !checkbox.checked)
    rowCheckboxes.forEach((checkbox) => {
      checkbox.checked = shouldCheck
    })
  }
}
