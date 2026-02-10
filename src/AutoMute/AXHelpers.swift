import ApplicationServices
import Cocoa

enum AXHelpers {
    static func axString(_ element: AXUIElement, _ attribute: String) -> String? {
        var value: CFTypeRef?
        let status = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard status == .success else { return nil }
        return value as? String
    }

    static func axBool(_ element: AXUIElement, _ attribute: String) -> Bool? {
        var value: CFTypeRef?
        let status = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard status == .success else { return nil }
        return value as? Bool
    }

    static func axSize(_ element: AXUIElement, _ attribute: String) -> CGSize? {
        var value: CFTypeRef?
        let status = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard status == .success, let axValue = value else { return nil }
        var size = CGSize.zero
        if AXValueGetType(axValue as! AXValue) == .cgSize {
            AXValueGetValue(axValue as! AXValue, .cgSize, &size)
            return size
        }
        return nil
    }

    static func axPoint(_ element: AXUIElement, _ attribute: String) -> CGPoint? {
        var value: CFTypeRef?
        let status = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard status == .success, let axValue = value else { return nil }
        var point = CGPoint.zero
        if AXValueGetType(axValue as! AXValue) == .cgPoint {
            AXValueGetValue(axValue as! AXValue, .cgPoint, &point)
            return point
        }
        return nil
    }
}
