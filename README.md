<div align="center">

[![Build Status][build status badge]][build status]
[![Platforms][platforms badge]][platforms]
[![Documentation][documentation badge]][documentation]
[![Matrix][matrix badge]][matrix]

</div>

# StableView
A list implementation that can preserve position

This is a SwiftUI wrapper around `NS`/`UITableView`. It is superfically-similar to SwiftUI's `List`, but with an additional property that can be used to control scroll position.

> [!WARNING]
> I'm just experimenting at the moment. This only kind of works.

## Integration

```swift
dependencies: [
    .package(url: "https://github.com/mattmassicotte/StableView", branch: "main")
]
```

## Usage

The position preservation system works via the `scrollState` binding.

```swift
struct AnchoredView: View {
    let items = ["one", "two", "three"]
    @State private var position: AnchoredListPosition<String>? = AnchoredListPosition(item: "two")

    public var body: some View {
       AnchoredList(items: items, position: $position) { item, row in
           Text("item: \(item)")
       }
    }
}
```

## Contributing and Collaboration

I would love to hear from you! Issues or pull requests work great. Both a [Matrix space][matrix] and [Discord][discord] are available for live help, but I have a strong bias towards answering in the form of documentation. You can also find me on [the web](https://www.massicotte.org).

I prefer collaboration, and would love to find ways to work together if you have a similar project.

I prefer indentation with tabs for improved accessibility. But, I'd rather you use the system you want and make a PR than hesitate because of whitespace.

By participating in this project you agree to abide by the [Contributor Code of Conduct](CODE_OF_CONDUCT.md).

[build status]: https://github.com/ChimeHQ/StableView/actions
[build status badge]: https://github.com/ChimeHQ/StableView/workflows/CI/badge.svg
[platforms]: https://swiftpackageindex.com/ChimeHQ/StableView
[platforms badge]: https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmattmassicotte%2FStableView%2Fbadge%3Ftype%3Dplatforms
[documentation]: https://swiftpackageindex.com/mattmassicotte/StableView/main/documentation
[documentation badge]: https://img.shields.io/badge/Documentation-DocC-blue
[matrix]: https://matrix.to/#/%23chimehq%3Amatrix.org
[matrix badge]: https://img.shields.io/matrix/chimehq%3Amatrix.org?label=Matrix
[discord]: https://discord.gg/esFpX6sErJ
