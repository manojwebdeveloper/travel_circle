import CoreImage.CIFilterBuiltins
import SwiftUI

struct QRCodeView: View {
    let value: String
    var size: CGFloat = 210

    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
            } else {
                ContentUnavailableView("QR unavailable", systemImage: "qrcode")
            }
        }
        .frame(width: size, height: size)
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityLabel("Invitation QR code")
    }

    private var image: UIImage? {
        filter.message = Data(value.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }

        let scale = size / output.extent.width
        let transformed = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        guard let cgImage = context.createCGImage(transformed, from: transformed.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}
