import SwiftUI

/// Lightweight confetti burst rendered with Canvas + TimelineView.
/// Show it briefly (see ContentView) when a milestone is reached.
struct ConfettiView: View {
    var duration: Double = 2.6
    private let start = Date()

    private struct Particle {
        let x: CGFloat      // 0...1 horizontal origin
        let delay: Double
        let vx: CGFloat
        let vy: CGFloat
        let size: CGFloat
        let color: Color
        let spin: Double
    }

    private let particles: [Particle]

    init(duration: Double = 2.6) {
        self.duration = duration
        let colors: [Color] = [Theme.level4, Theme.level3, Theme.accent, Theme.text, Theme.level1]
        var rng = SystemRandomNumberGenerator()
        particles = (0..<120).map { _ in
            Particle(
                x: CGFloat.random(in: 0.1...0.9, using: &rng),
                delay: Double.random(in: 0...0.25, using: &rng),
                vx: CGFloat.random(in: -0.9...0.9, using: &rng),
                vy: CGFloat.random(in: 0.8...1.4, using: &rng),
                size: CGFloat.random(in: 5...11, using: &rng),
                color: colors.randomElement(using: &rng) ?? Theme.level4,
                spin: Double.random(in: -7...7, using: &rng)
            )
        }
    }

    var body: some View {
        TimelineView(.animation) { tl in
            Canvas { ctx, size in
                let t = tl.date.timeIntervalSince(start)
                for p in particles {
                    let lt = t - p.delay
                    if lt < 0 { continue }
                    let progress = lt / duration
                    if progress > 1 { continue }

                    let x = p.x * size.width + p.vx * 240 * CGFloat(lt)
                    // burst upward, then gravity pulls down
                    let y = size.height * 0.30
                        - p.vy * 520 * CGFloat(lt)
                        + 0.5 * 900 * CGFloat(lt * lt)
                    if y > size.height + 24 { continue }

                    let base = Path(CGRect(x: -p.size / 2, y: -p.size / 2,
                                           width: p.size, height: p.size * 0.6))
                    let transform = CGAffineTransform(translationX: x, y: y)
                        .rotated(by: CGFloat(p.spin * lt))
                    ctx.opacity = max(0, 1 - progress)
                    ctx.fill(base.applying(transform), with: .color(p.color))
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}
