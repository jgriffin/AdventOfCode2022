//
// Created by John Griffin on 12/21/22
//

import Charts
import SwiftUI

struct Chart_Previews: PreviewProvider {
    static var previews: some View {
        Chart {
            PointMark(x: .value("x", 3), y: .value("y", 5))
                .symbol(BubbleShape())
                .symbolSize(100)

            RectangleMark(
                xStart: .value("xFloat", 6.5),
                xEnd: .value("xFloat", 7.5),
                yStart: .value("yFloat", 4.5),
                yEnd: .value("yFloat", 5.5)
            )
            .annotation(position: .overlay, alignment: .center, spacing: 1) {
                Rectangle().foregroundStyle(.green)
                    .rotationEffect(.degrees(45))
            }
        }
        .chartXScale(domain: 0 ... 10)
        .chartYScale(domain: 0 ... 10)
        .chartSymbolSizeScale(domain: 0...10, range: 0...1, type: .linear)
        .chartXAxis {
            AxisMarks(values: .stride(by: 1)) {
                AxisGridLine()
            }
            AxisMarks { _ in
                AxisTick()
                AxisValueLabel()
            }
        }
        .chartYAxis {
            AxisMarks(values: .stride(by: 1)) {
                AxisGridLine()
            }
            AxisMarks { _ in
                AxisTick()
                AxisValueLabel()
            }
        }
        .chartPlotStyle { content in
            content
                .aspectRatio(1, contentMode: .fit)
                .padding()
        }
    }
}

struct BubbleShape: ChartSymbolShape {
    var perceptualUnitRect: CGRect = .init(x: 0, y: 0, width: 1, height: 1) // .init(x: -1, y: -1, width: 2, height: 2)
    func path(in rect: CGRect) -> Path {
        Path(ellipseIn: rect)
    }
}
