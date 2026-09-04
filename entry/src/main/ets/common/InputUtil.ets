export function keepWeight(value: string): string {
  let out: string = '';
  let hasDot: boolean = false;
  for (let i = 0; i < value.length; i++) {
    const ch: string = value.charAt(i);
    if (ch >= '0' && ch <= '9') {
      out += ch;
    } else if (ch === '.' && !hasDot) {
      out += ch;
      hasDot = true;
    }
  }
  return out;
}

export function keepReps(value: string): string {
  let out: string = '';
  for (let i = 0; i < value.length; i++) {
    const ch: string = value.charAt(i);
    if (ch >= '0' && ch <= '9') {
      out += ch;
    }
  }
  return out;
}
