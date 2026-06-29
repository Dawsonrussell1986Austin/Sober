import SwiftUI

/// Scripture (World English Bible — public domain) for the faith-based content.
enum Scripture {
    struct Verse { let ref: String; let text: String }

    static let verses: [Verse] = [
        .init(ref: "Philippians 4:13", text: "I can do all things through Christ, who strengthens me."),
        .init(ref: "1 Corinthians 10:13", text: "God is faithful, who will not allow you to be tempted above what you are able, but will with the temptation also make the way of escape."),
        .init(ref: "Isaiah 41:10", text: "Don’t be afraid, for I am with you. Don’t be dismayed, for I am your God. I will strengthen you. Yes, I will help you."),
        .init(ref: "2 Corinthians 5:17", text: "If anyone is in Christ, he is a new creation. The old things have passed away. Behold, all things have become new."),
        .init(ref: "Psalm 46:1", text: "God is our refuge and strength, a very present help in trouble."),
        .init(ref: "Matthew 11:28", text: "Come to me, all you who labor and are heavily burdened, and I will give you rest."),
        .init(ref: "2 Corinthians 12:9", text: "My grace is sufficient for you, for my power is made perfect in weakness."),
        .init(ref: "Romans 12:2", text: "Don’t be conformed to this world, but be transformed by the renewing of your mind."),
        .init(ref: "Galatians 5:1", text: "Stand firm therefore in the liberty by which Christ has made us free, and don’t be entangled again with a yoke of bondage."),
        .init(ref: "Psalm 40:2", text: "He brought me up out of a horrible pit, out of the miry clay. He set my feet on a rock, and gave me a firm place to stand."),
        .init(ref: "1 Peter 5:7", text: "Cast all your worries on him, because he cares for you."),
        .init(ref: "Romans 8:1", text: "There is therefore now no condemnation to those who are in Christ Jesus."),
        .init(ref: "Psalm 51:10", text: "Create in me a clean heart, O God. Renew a right spirit within me."),
        .init(ref: "Ezekiel 36:26", text: "I will give you a new heart, and I will put a new spirit within you."),
        .init(ref: "John 8:36", text: "If therefore the Son makes you free, you will be free indeed."),
        .init(ref: "Lamentations 3:22-23", text: "His compassion doesn’t fail. They are new every morning. Great is your faithfulness."),
    ]

    static let milestoneVerse: [Int: Verse] = [
        7:   .init(ref: "Lamentations 3:22-23", text: "His compassions are new every morning."),
        30:  .init(ref: "2 Corinthians 5:17", text: "If anyone is in Christ, he is a new creation."),
        90:  .init(ref: "Philippians 4:13", text: "I can do all things through Christ, who strengthens me."),
        180: .init(ref: "Isaiah 41:10", text: "I will strengthen you. Yes, I will help you."),
        365: .init(ref: "Galatians 5:1", text: "Stand firm in the liberty by which Christ has made us free."),
    ]

    static let serenityShort = "God, grant me the serenity to accept the things I cannot change, the courage to change the things I can, and the wisdom to know the difference."
    static let serenityFull = serenityShort + " Living one day at a time; enjoying one moment at a time; accepting hardship as a pathway to peace; trusting that you will make all things right if I surrender to your will; that I may be reasonably happy in this life, and supremely happy with you forever in the next. Amen."

    static func verseOfDay() -> Verse {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return verses[(day - 1) % verses.count]
    }
}

struct VerseOfDayView: View {
    var body: some View {
        let v = Scripture.verseOfDay()
        VStack(alignment: .leading, spacing: 8) {
            Text("VERSE OF THE DAY")
                .font(.system(size: 11, weight: .bold)).tracking(0.5).foregroundColor(Theme.accent)
            Text("\u{201C}\(v.text)\u{201D}")
                .font(.system(size: 16, design: .serif)).foregroundColor(Theme.text)
                .fixedSize(horizontal: false, vertical: true)
            Text("— \(v.ref) (WEB)").font(.system(size: 13, weight: .semibold)).foregroundColor(Theme.textDim)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(faithCard)
    }
}

struct SerenityPrayerView: View {
    @State private var expanded = false
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SERENITY PRAYER")
                .font(.system(size: 11, weight: .bold)).tracking(0.5).foregroundColor(Theme.accent)
            Text(expanded ? Scripture.serenityFull : Scripture.serenityShort)
                .font(.system(size: 15, design: .serif)).foregroundColor(Theme.text)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                withAnimation { expanded.toggle() }
            } label: {
                Text(expanded ? "Show less" : "Show full prayer")
                    .font(.system(size: 13, weight: .semibold)).foregroundColor(Theme.accent)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(faithCard)
    }
}

/// Shared card background for faith content.
private var faithCard: some View {
    RoundedRectangle(cornerRadius: 16)
        .fill(Theme.surface)
        .overlay(RoundedRectangle(cornerRadius: 16).fill(LinearGradient(colors: [Theme.accent.opacity(0.08), .clear], startPoint: .top, endPoint: .bottom)))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.border))
}
