import SwiftUI

struct ThemeToggle: View {
    @AppStorage("colorScheme") private var colorSchemePreference: String = "system"
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Menu {
            Button(action: { colorSchemePreference = "light" }) {
                HStack {
                    Text("Light")
                    if colorSchemePreference == "light" {
                        Image(systemName: "checkmark")
                    }
                }
            }
            
            Button(action: { colorSchemePreference = "dark" }) {
                HStack {
                    Text("Dark")
                    if colorSchemePreference == "dark" {
                        Image(systemName: "checkmark")
                    }
                }
            }
            
            Button(action: { colorSchemePreference = "system" }) {
                HStack {
                    Text("System")
                    if colorSchemePreference == "system" {
                        Image(systemName: "checkmark")
                    }
                }
            }
        } label: {
            Image(systemName: colorSchemeIcon)
                .font(.system(size: 20))
                .foregroundStyle(.primary)
        }
    }
    
    private var colorSchemeIcon: String {
        switch colorSchemePreference {
        case "light": return "sun.max.fill"
        case "dark": return "moon.fill"
        default: return "circle.lefthalf.filled"
        }
    }
}

