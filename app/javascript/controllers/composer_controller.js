import { Controller } from "@hotwired/stimulus"

// The composer's two obligations after a send: the field is cleared and focus returns
// to it (ADR 009). Enter sends; Shift+Enter breaks a line.
export default class extends Controller {
  static targets = ["field"]

  reset(event) {
    if (event.detail && event.detail.success === false) return
    this.element.reset()
    this.fieldTarget.focus()
  }

  keydown(event) {
    if (event.key !== "Enter" || event.shiftKey || event.target !== this.fieldTarget) return
    event.preventDefault()
    if (this.fieldTarget.value.trim() === "") return
    this.element.requestSubmit()
  }
}
