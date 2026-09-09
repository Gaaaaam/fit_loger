import { ChartPoint, datedChartPositions, TrendPoint } from '../common/TrendLogic';

@Component
export struct TrendSparkline {
  @Prop points: TrendPoint[] = [];
  @Prop chartHeight: number = 44;
  @Prop showLabels: boolean = false;
  @Prop unit: string = '';
  @State boxW: number = 0;
  @State boxH: number = 44;

  // 按真实日期间距摆放数据点，而不是按数据点序号平均分布——
  // 两个相隔 1 天与相隔 30 天的点在图上的位置应该完全不同。
  private linePoints(): number[][] {
    const pts: number[][] = [];
    const chartPoints: ChartPoint[] = datedChartPositions(this.points);
    const n: number = chartPoints.length;
    if (n < 2 || this.boxW < 8) {
      return pts;
    }
    let minV: number = chartPoints[0].value;
    let maxV: number = chartPoints[0].value;
    for (let i = 1; i < n; i++) {
      if (chartPoints[i].value < minV) {
        minV = chartPoints[i].value;
      }
      if (chartPoints[i].value > maxV) {
        maxV = chartPoints[i].value;
      }
    }
    const pad: number = 6;
    const innerW: number = this.boxW - pad * 2;
    const innerH: number = this.boxH - pad * 2;
    const flat: boolean = maxV === minV;
    for (let i = 0; i < n; i++) {
      const x: number = pad + innerW * chartPoints[i].xRatio;
      let y: number = pad + innerH / 2;
      if (!flat) {
        y = pad + innerH * (1 - (chartPoints[i].value - minV) / (maxV - minV));
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

  private firstLabel(): string {
    if (this.points.length === 0) {
      return '';
    }
    return this.points[0].date.slice(5);
  }

  private lastLabel(): string {
    if (this.points.length === 0) {
      return '';
    }
    return this.points[this.points.length - 1].date.slice(5);
  }

  build() {
    Column() {
      Stack() {
        if (this.points.length >= 2 && this.boxW > 8) {
          Polyline()
            .width(this.boxW)
            .height(this.boxH)
            .points(this.linePoints())
            .stroke($r('app.color.accent'))
            .strokeWidth(2)
            .fillOpacity(0)
        } else if (this.points.length === 1 && this.boxW > 8) {
          Circle()
            .width(6)
            .height(6)
            .fill($r('app.color.accent'))
            .position({ x: this.singleX(), y: this.singleY() })
        }
      }
      .width('100%')
      .height(this.chartHeight)
      .onAreaChange((_oldArea: Area, newArea: Area) => {
        this.boxW = newArea.width as number;
        this.boxH = newArea.height as number;
      })
      if (this.showLabels && this.points.length > 0) {
        Row() {
          Text(this.firstLabel())
            .fontSize(11)
            .fontColor($r('app.color.text_secondary'))
          Blank()
          if (this.unit.length > 0) {
            Text(this.unit)
              .fontSize(11)
              .fontColor($r('app.color.text_secondary'))
          }
          Blank()
          Text(this.lastLabel())
            .fontSize(11)
            .fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .margin({ top: 4 })
      }
    }
    .width('100%')
  }
}
