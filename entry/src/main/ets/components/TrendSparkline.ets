@Component
export struct TrendSparkline {
  @Prop values: number[] = [];
  @State boxW: number = 0;
  @State boxH: number = 44;

  private linePoints(): number[][] {
    const pts: number[][] = [];
    const n: number = this.values.length;
    if (n < 2 || this.boxW < 8) {
      return pts;
    }
    let minV: number = this.values[0];
    let maxV: number = this.values[0];
    for (let i = 1; i < n; i++) {
      if (this.values[i] < minV) {
        minV = this.values[i];
      }
      if (this.values[i] > maxV) {
        maxV = this.values[i];
      }
    }
    const pad: number = 6;
    const innerW: number = this.boxW - pad * 2;
    const innerH: number = this.boxH - pad * 2;
    const flat: boolean = maxV === minV;
    for (let i = 0; i < n; i++) {
      const x: number = pad + (innerW * i) / (n - 1);
      let y: number = pad + innerH / 2;
      if (!flat) {
        y = pad + innerH * (1 - (this.values[i] - minV) / (maxV - minV));
      }
      pts.push([x, y]);
    }
    return pts;
  }

  private singleX(): number {
    if (this.boxW <= 0) {
      return 0;
    }
    return this.boxW / 2 - 3;
  }

  private singleY(): number {
    if (this.boxH <= 0) {
      return 0;
    }
    return this.boxH / 2 - 3;
  }

  build() {
    Stack() {
      if (this.values.length >= 2 && this.boxW > 8) {
        Polyline()
          .width(this.boxW)
          .height(this.boxH)
          .points(this.linePoints())
          .stroke($r('app.color.accent'))
          .strokeWidth(2)
          .fillOpacity(0)
      } else if (this.values.length === 1 && this.boxW > 8) {
        Circle()
          .width(6)
          .height(6)
          .fill($r('app.color.accent'))
          .position({ x: this.singleX(), y: this.singleY() })
      }
    }
    .width('100%')
    .height(44)
    .onAreaChange((_oldArea: Area, newArea: Area) => {
      this.boxW = newArea.width as number;
      this.boxH = newArea.height as number;
    })
  }
}
