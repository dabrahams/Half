//
//  Half.swift
//  Half
//
//  Copyright © 2022 SomeRandomiOSDev. All rights reserved.
//

#if SWIFT_PACKAGE
import CHalf
#endif

#if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)
import CoreGraphics.CGBase
#endif // #if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)

#if swift(>=5.0)
// MARK: - Half Definition

#if swift(>=5.1)
/// A half-precision, floating-point value type.
@frozen public struct Half {

    // MARK: Public Properties

    public var _value: half_t

    // MARK: Initialization

    @_transparent
    public init() {
        self._value = _half_zero()
    }

    @_transparent
    public init(_ _value: half_t) {
        self._value = _value
    }
}
#else
/// A half-precision, floating-point value type.
public struct Half {

    // MARK: Public Properties

    public var _value: half_t

    // MARK: Initialization

    @_transparent
    public init() {
        self._value = _half_zero()
    }

    @_transparent
    public init(_ _value: half_t) {
        self._value = _value
    }
}
#endif

// MARK: - Half Extension

extension Half {

    /**
     The bit pattern of the value’s encoding.

     The bit pattern matches the binary interchange format defined by the [IEEE 754
     specification](http://ieeexplore.ieee.org/servlet/opac?punumber=4610933).

     - Note: This documentation comment was copied from `Double`.
     */
    @inlinable
    public var bitPattern: UInt16 {
        return _half_to_raw(_value)
    }

    /**
     Creates a new value with the given bit pattern.

     The value passed as bitPattern is interpreted in the binary interchange format
     defined by the [IEEE 754
     specification](http://ieeexplore.ieee.org/servlet/opac?punumber=4610933).

     - Parameters:
       - bitPattern: The integer encoding of a `Half` instance.

     - Note: This documentation comment was copied from `Double`.
     */
    @inlinable
    public init(bitPattern: UInt16) {
        self._value = _half_from_raw(bitPattern)
    }

    /**
     Creates a NaN (“not a number”) value with the specified payload.

     NaN values compare not equal to every value, including themselves. Most
     operations with a NaN operand produce a NaN result. Don’t use the equal-to
     operator (==) to test whether a value is NaN. Instead, use the value’s isNaN
     property.

     ```swift
     let x = Half(nan: 0, signaling: false)
     print(x == .nan)
     // Prints "false"
     print(x.isNaN)
     // Prints "true"
     ```

     - Parameters:
       - payload: The payload to use for the new NaN value.
       - signaling: Pass true to create a signaling NaN or false to create a quiet NaN.

     - Note: This documentation comment was copied from `Double`.
     */
    @inlinable
    public init(nan payload: UInt16, signaling: Bool) {
        precondition(payload < (Half.quietNaNMask &>> 1), "NaN payload is not encodable.")

        var significand = payload
        significand |= Half.quietNaNMask &>> (signaling ? 1 : 0)

        self.init(sign: .plus, exponentBitPattern: Half.infinityExponent, significandBitPattern: significand)
    }
}

// MARK: - CustomStringConvertible Protocol Conformance

extension Half: CustomStringConvertible {

    /**
     A textual representation of the value.

     For any finite value, this property provides a string that can be converted back
     to an instance of `Half` without rounding errors. That is, if x is an instance
     of `Half`, then `Half`(x.description) == x is always true. For any NaN value,
     the property’s value is “nan”, and for positive and negative infinity its value
     is “inf” and “-inf”.

     - Note: This documentation comment was copied from `Double`.
     */
    public var description: String {
        if isNaN {
            return "nan"
        }

        return _half_to_float(_value).description
    }
}

// MARK: - CustomStringConvertible Protocol Conformance

extension Half: CustomDebugStringConvertible {

    /**
     A textual representation of the value, suitable for debugging.

     This property has the same value as the description property, except that NaN
     values are printed in an extended format.

     - Note: This documentation comment was copied from `Double`.
     */
    public var debugDescription: String {
        return _half_to_float(_value).description
    }
}

// MARK: - TextOutputStreamable Protocol Conformance

extension Half: TextOutputStreamable {

    /**
     Writes a textual representation of this instance into the given output stream.

     - Note: This documentation comment was inherited from `TextOutputStreamable`.
     */
    public func write<Target>(to target: inout Target) where Target: TextOutputStream {
        _half_to_float(_value).write(to: &target)
    }
}

// MARK: - Internal Constants

extension Half {

    @inlinable @inline(__always)
    internal static var significandMask: UInt16 {
        return 1 &<< UInt16(significandBitCount) - 1
    }

    @inlinable @inline(__always)
    internal static var infinityExponent: UInt {
        return 1 &<< UInt(exponentBitCount) - 1
    }

    @inlinable @inline(__always)
    internal static var exponentBias: UInt {
        return infinityExponent &>> 1
    }

    @inlinable @inline(__always)
    internal static var quietNaNMask: UInt16 {
        return 1 &<< UInt16(significandBitCount - 1)
    }
}

// MARK: - BinaryFloatingPoint Protocol Conformance

extension Half: BinaryFloatingPoint {

    /**
     The number of bits used to represent the type's exponent.

     A binary floating-point type's `exponentBitCount` imposes a limit on the
     range of the exponent for normal, finite values. The *exponent bias* of
     a type `F` can be calculated as the following, where `**` is
     exponentiation:

         let bias = 2 ** (F.exponentBitCount - 1) - 1

     The least normal exponent for values of the type `F` is `1 - bias`, and
     the largest finite exponent is `bias`. An all-zeros exponent is reserved
     for subnormals and zeros, and an all-ones exponent is reserved for
     infinity and NaN.

     For example, the `Float` type has an `exponentBitCount` of 8, which gives
     an exponent bias of `127` by the calculation above.

         let bias = 2 ** (Float.exponentBitCount - 1) - 1
         // bias == 127
         print(Float.greatestFiniteMagnitude.exponent)
         // Prints "127"
         print(Float.leastNormalMagnitude.exponent)
         // Prints "-126"

     - Note: This documentation comment was inherited from `BinaryFloatingPoint`.
     */
    @inlinable
    public static var exponentBitCount: Int {
        return 5
    }

    /**
     The available number of fractional significand bits.

     For fixed-width floating-point types, this is the actual number of
     fractional significand bits.

     For extensible floating-point types, `significandBitCount` should be the
     maximum allowed significand width (without counting any leading integral
     bit of the significand). If there is no upper limit, then
     `significandBitCount` should be `Int.max`.

     - Note: This documentation comment was inherited from `BinaryFloatingPoint`.
     */
    @inlinable
    public static var significandBitCount: Int {
        return 10
    }

    /**
     The raw encoding of the value's exponent field.

     This value is unadjusted by the type's exponent bias.

     - Note: This documentation comment was inherited from `BinaryFloatingPoint`.
     */
    @inlinable
    public var exponentBitPattern: UInt {
        return UInt(bitPattern &>> UInt16(Half.significandBitCount)) & Half.infinityExponent
    }

    /**
     The raw encoding of the value's significand field.

     The `significandBitPattern` property does not include the leading
     integral bit of the significand, even for types like `Float80` that
     store it explicitly.

     - Note: This documentation comment was inherited from `BinaryFloatingPoint`.
     */
    @inlinable
    public var significandBitPattern: UInt16 {
        return bitPattern & Half.significandMask
    }

    //

    /**
     Creates a new value from the given sign, exponent, and significand.

     The following example uses this initializer to create a new `Half`
     instance. `Half` is a binary floating-point type that has a radix of
     `2`.

         let x = Half(sign: .plus, exponent: -2, significand: 1.5)
         // x == 0.375

     This initializer is equivalent to the following calculation, where `**`
     is exponentiation, computed as if by a single, correctly rounded,
     floating-point operation:

         let sign: FloatingPointSign = .plus
         let exponent = -2
         let significand = 1.5
         let y = (sign == .minus ? -1 : 1) * significand * Half.radix ** exponent
         // y == 0.375

     As with any basic operation, if this value is outside the representable
     range of the type, overflow or underflow occurs, and zero, a subnormal
     value, or infinity may result. In addition, there are two other edge
     cases:

     - If the value you pass to `significand` is zero or infinite, the result
       is zero or infinite, regardless of the value of `exponent`.
     - If the value you pass to `significand` is NaN, the result is NaN.

     For any floating-point value `x` of type `F`, the result of the following
     is equal to `x`, with the distinction that the result is canonicalized
     if `x` is in a noncanonical encoding:

         let x0 = F(sign: x.sign, exponent: x.exponent, significand: x.significand)

     - Parameters:
       - sign: The sign to use for the new value.
       - exponent: The new value's exponent.
       - significand: The new value's significand.

     - Note: This documentation comment was inherited from `FloatingPoint`.
     */
    @inlinable
    public init(sign: FloatingPointSign, exponentBitPattern: UInt, significandBitPattern: UInt16) {
        let signBits: UInt16 = (sign == .minus ? 1 : 0) &<< (Half.exponentBitCount + Half.significandBitCount)
        let exponentBits = UInt16((exponentBitPattern & Half.infinityExponent) &<< Half.significandBitCount)
        let significandBits = significandBitPattern & Half.significandMask

        self.init(bitPattern: signBits | exponentBits | significandBits)
    }

    /**
     Creates a new instance that approximates the given value.

     The value of other is rounded to a representable value, if necessary. A NaN
     passed as other results in another NaN, with a signaling NaN value converted to
     quiet NaN.

     ```swift
     let x: Float = 21.25
     let y = Half(x)
     // y == 21.25

     let z = Half(Float.nan)
     // z.isNaN == true
     ```

     - Parameters:
       - other: The value to use for the new instance.

     - Note: This documentation comment was copied from `Double`.
     */
    @inlinable @inline(__always)
    public init(_ other: Float) {
        if other.isInfinite {
            let infinity = Half.infinity
            self = Half(sign: other.sign, exponentBitPattern: infinity.exponentBitPattern, significandBitPattern: infinity.significandBitPattern)
        } else if other.isNaN {
            self = .nan
        } else {
            _value = _half_from(other)
        }
    }

    /**
     Creates a new instance that approximates the given value.

     The value of other is rounded to a representable value, if necessary. A NaN
     passed as other results in another NaN, with a signaling NaN value converted to
     quiet NaN.

     ```swift
     let x: Double = 21.25
     let y = Half(x)
     // y == 21.25

     let z = Half(Double.nan)
     // z.isNaN == true
     ```

     - Parameters:
       - other: The value to use for the new instance.

     - Note: This documentation comment was copied from `Double`.
     */
    @inlinable @inline(__always)
    public init(_ other: Double) {
        if other.isInfinite {
            let infinity = Half.infinity
            self = Half(sign: other.sign, exponentBitPattern: infinity.exponentBitPattern, significandBitPattern: infinity.significandBitPattern)
        } else if other.isNaN {
            self = .nan
        } else {
            _value = _half_from(other)
        }
    }

#if !(os(Windows) || os(Android)) && (arch(i386) || arch(x86_64))
    /**
     Creates a new instance that approximates the given value.

     The value of other is rounded to a representable value, if necessary. A NaN
     passed as other results in another NaN, with a signaling NaN value converted to
     quiet NaN.

     ```swift
     let x: Float80 = 21.25
     let y = Half(x)
     // y == 21.25

     let z = Half(Float80.nan)
     // z.isNaN == true
     ```

     - Parameters:
       - other: The value to use for the new instance.

     - Note: This documentation comment was copied from `Double`.
     */
    @inlinable @inline(__always)
    public init(_ other: Float80) {
        if other.isInfinite {
            let infinity = Half.infinity
            self = Half(sign: other.sign, exponentBitPattern: infinity.exponentBitPattern, significandBitPattern: infinity.significandBitPattern)
        } else if other.isNaN {
            self = .nan
        } else {
            _value = _half_from(Double(other))
        }
    }
#endif

#if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)
    // Not part of the protocol
    /**
     Creates a new instance that approximates the given value.

     The value of other is rounded to a representable value, if necessary. A NaN
     passed as other results in another NaN, with a signaling NaN value converted to
     quiet NaN.

     ```swift
     let x: CGFloat = 21.25
     let y = Half(x)
     // y == 21.25

     let z = Half(CGFloat.nan)
     // z.isNaN == true
     ```

     - Parameters:
       - other: The value to use for the new instance.

     - Note: This documentation comment was copied from `Double`.
     */
    @inlinable @inline(__always)
    public init(_ other: CGFloat) {
        self.init(other.native)
    }

#if !((os(macOS) || targetEnvironment(macCatalyst)) && arch(x86_64))
    /**
     Creates a new instance that approximates the given value.

     The value of other is rounded to a representable value, if necessary. A NaN
     passed as other results in another NaN, with a signaling NaN value converted to
     quiet NaN.

     ```swift
     let x: Float16 = 21.25
     let y = Half(x)
     // y == 21.25

     let z = Half(Float16.nan)
     // z.isNaN == true
     ```

     - Parameters:
       - other: The value to use for the new instance.

     - Note: This documentation comment was copied from `Double`.
     */
    @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
    @inlinable @inline(__always)
    public init(_ other: Float16) {
        if other.isInfinite {
            let infinity = Half.infinity
            self = Half(sign: other.sign, exponentBitPattern: infinity.exponentBitPattern, significandBitPattern: infinity.significandBitPattern)
        } else if other.isNaN {
            self = .nan
        } else {
            self.init(bitPattern: other.bitPattern)
        }
    }
#endif // #if !((os(macOS) || targetEnvironment(macCatalyst)) && arch(x86_64))
#endif // #if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)

    /**
     Creates a new instance from the given value, rounded to the closest possible
     representation.

     If two representable values are equally close, the result is the value with more
     trailing zeros in its significand bit pattern.

     - Parameters:
       - value: A floating-point value to be converted.

     - Note: This documentation comment was copied from `Double`.
     */
    @inlinable @inline(__always)
    public init<Source>(_ value: Source) where Source: BinaryFloatingPoint {
        if let half = value as? Half {
            self.init(half._value)
        } else if value.isInfinite {
            let infinity = Half.infinity
            self = Half(sign: value.sign, exponentBitPattern: infinity.exponentBitPattern, significandBitPattern: infinity.significandBitPattern)
        } else if value.isNaN {
            if value.isSignalingNaN {
                self = .signalingNaN
            } else {
                self = .nan
            }
        } else {
            self.init(_half_from(Float(value)))
        }
    }

    /**
     Creates a new instance from the given value, if it can be represented exactly.

     If the given floating-point value cannot be represented exactly, the result is
     `nil`.

     - Parameters:
       - value: A floating-point value to be converted.

     - Note: This documentation comment was copied from `Double`.
     */
    @inlinable
    public init?<Source>(exactly value: Source) where Source: BinaryFloatingPoint {
        self.init(value)

        if isInfinite || value.isInfinite {
            if value.isInfinite && (!isInfinite || sign != value.sign) {
                // If source is infinite but this isn't or this is but with a different sign
                return nil
            } else if isInfinite && !value.isInfinite {
                // If source isn't infinite but this is
                return nil
            }
        } else if isNaN || value.isNaN {
            if value.isNaN && (!isNaN || isSignalingNaN != value.isSignalingNaN) {
                // If source is NaN but this isn't or this is but one is signaling while the other isn't
                return nil
            } else if isNaN && !value.isNaN {
                // If source isn't NaN but this is
                return nil
            }
        } else if Source(self) != value {
            // If casting half back to source isn't equal to original source
            return nil
        }
    }

    //

    /**
     The floating-point value with the same sign and exponent as this value, but with
     a significand of 1.0.

     A *binade* is a set of binary floating-point values that all have the same sign
     and exponent. The binade property is a member of the same binade as this value,
     but with a unit significand.

     In this example, x has a value of `21.5`, which is stored as `1.34375 * 2**4`,
     where `**` is exponentiation. Therefore, `x.binade` is equal to `1.0 * 2**4`, or
     `16.0`.

     ```swift
     let x = 21.5
     // x.significand == 1.34375
     // x.exponent == 4

     let y = x.binade
     // y == 16.0
     // y.significand == 1.0
     // y.exponent == 4
     ```

     - Note: This documentation comment was inherited from `BinaryFloatingPoint`.
     */
    @inlinable
    public var binade: Half {
        guard isFinite else { return .nan }

        #if !arch(arm)
        if isSubnormal {
            let bitPattern = (self * 0x1p10).bitPattern & (-Half.infinity).bitPattern
            return Half(bitPattern: bitPattern) * .ulpOfOne
        }
        #endif

        return Half(bitPattern: bitPattern & (-Half.infinity).bitPattern)
    }

    /**
     The number of bits required to represent the value’s significand.

     If this value is a finite nonzero number, `significandWidth` is the number of
     fractional bits required to represent the value of `significand`; otherwise,
     `significandWidth` is `-1`. The value of `significandWidth` is always `-1` or
     between zero and `significandBitCount`. For example:

     - For any representable power of two, `significandWidth` is zero, because
       `significand` is `1.0`.
     - If x is 10, `x.significand` is `1.01` in binary, so `x.significandWidth` is 2.
     - If x is Float.pi, `x.significand` is `1.10010010000111111011011` in binary,
       and `x.significandWidth` is 23.

     - Note: This documentation comment was inherited from `BinaryFloatingPoint`.
     */
    @inlinable
    public var significandWidth: Int {
        let trailingZeroBits = significandBitPattern.trailingZeroBitCount
        if isNormal {
            guard significandBitPattern != 0 else { return 0 }
            return Half.significandBitCount &- trailingZeroBits
        }
        if isSubnormal {
            let leadingZeroBits = significandBitPattern.leadingZeroBitCount
            return UInt16.bitWidth &- (trailingZeroBits &+ leadingZeroBits &+ 1)
        }
        return -1
    }
}

// MARK: - ExpressibleByFloatLiteral Protocol Conformance

extension Half: ExpressibleByFloatLiteral {

    /**
     Creates an instance initialized to the specified floating-point value.

     Do not call this initializer directly. Instead, initialize a variable or
     constant using a floating-point literal. For example:

     ```swift
     let x = 21.5
     ```

     In this example, the assignment to the `x` constant calls this floating-point
     literal initializer behind the scenes.

     - Parameters:
       - value: The value to create.

     - Note: This documentation comment was inherited from
     `ExpressibleByFloatLiteral`.
     */
    @_transparent
    public init(floatLiteral value: Float) {
        self.init(value)
    }
}

// MARK: - FloatingPoint Protocol Conformance

extension Half: FloatingPoint {

    /**
     Creates a new value from the given sign, exponent, and significand.

     The following example uses this initializer to create a new `Half`
     instance. `Half` is a binary floating-point type that has a radix of
     `2`.

         let x = Half(sign: .plus, exponent: -2, significand: 1.5)
         // x == 0.375

     This initializer is equivalent to the following calculation, where `**`
     is exponentiation, computed as if by a single, correctly rounded,
     floating-point operation:

         let sign: FloatingPointSign = .plus
         let exponent = -2
         let significand = 1.5
         let y = (sign == .minus ? -1 : 1) * significand * Half.radix ** exponent
         // y == 0.375

     As with any basic operation, if this value is outside the representable
     range of the type, overflow or underflow occurs, and zero, a subnormal
     value, or infinity may result. In addition, there are two other edge
     cases:

     - If the value you pass to `significand` is zero or infinite, the result
       is zero or infinite, regardless of the value of `exponent`.
     - If the value you pass to `significand` is NaN, the result is NaN.

     For any floating-point value `x` of type `F`, the result of the following
     is equal to `x`, with the distinction that the result is canonicalized
     if `x` is in a noncanonical encoding:

         let x0 = F(sign: x.sign, exponent: x.exponent, significand: x.significand)

     This initializer implements the `scaleB` operation defined by the [IEEE
     754 specification][spec].

     [spec]: http://ieeexplore.ieee.org/servlet/opac?punumber=4610933

     - Parameters:
       - sign: The sign to use for the new value.
       - exponent: The new value's exponent.
       - significand: The new value's significand.

     - Note: This documentation comment was inherited from `FloatingPoint`.
     */
    @inlinable
    public init(sign: FloatingPointSign, exponent: Int, significand: Half) {
        var result = significand
        if sign == .minus { result = -result }

        if significand.isFinite && !significand.isZero {
            var clamped = exponent
            let leastNormalExponent = 1 - Int(Half.exponentBias)
            let greatestFiniteExponent = Int(Half.exponentBias)

            if clamped < leastNormalExponent {
                clamped = max(clamped, 3 * leastNormalExponent)

                while clamped < leastNormalExponent {
                    result *= Half.leastNormalMagnitude
                    clamped -= leastNormalExponent
                }
            } else if clamped > greatestFiniteExponent {
                let step = Half(sign: .plus, exponentBitPattern: Half.infinityExponent - 1, significandBitPattern: 0)
                clamped = min(clamped, 3 * greatestFiniteExponent)

                while clamped > greatestFiniteExponent {
                    result *= step
                    clamped -= greatestFiniteExponent
                }
            }

            let scale = Half(sign: .plus, exponentBitPattern: UInt(Int(Half.exponentBias) + clamped), significandBitPattern: 0)
            result *= scale
        }

        self = result
    }

    /**
     Creates a new value, rounded to the closest possible representation.

     If two representable values are equally close, the result is the value
     with more trailing zeros in its significand bit pattern.

     - Parameters:
       - value: The integer to convert to a floating-point value.

     - Note: This documentation comment was inherited from `FloatingPoint`.
     */
    @_transparent
    public init(_ value: Int) {
        _value = _half_from(value)
    }

    /**
     Creates a new value, rounded to the closest possible representation.

     If two representable values are equally close, the result is the value
     with more trailing zeros in its significand bit pattern.

     - Parameters:
       - value: The integer to convert to a floating-point value.

     - Note: This documentation comment was inherited from `FloatingPoint`.
     */
    @inlinable @inline(__always)
    public init<Source: BinaryInteger>(_ value: Source) {
        if value.bitWidth <= MemoryLayout<Int>.size * 8 {
            if Source.isSigned {
                let asInt = Int(truncatingIfNeeded: value)
                self.init(_half_from(asInt))
            } else {
                let asUInt = UInt(truncatingIfNeeded: value)
                self.init(_half_from(asUInt))
            }
        } else {
            self.init(Float(value))
        }
    }

    //

    /**
     The exponent of the floating-point value.

     The *exponent* of a floating-point value is the integer part of the
     logarithm of the value's magnitude. For a value `x` of a floating-point
     type `F`, the magnitude can be calculated as the following, where `**`
     is exponentiation:

         let magnitude = x.significand * F.radix ** x.exponent

     In the next example, `y` has a value of `21.5`, which is encoded as
     `1.34375 * 2 ** 4`. The significand of `y` is therefore 1.34375.

         let y: Half = 21.5
         // y.significand == 1.34375
         // y.exponent == 4
         // Half.radix == 2

     The `exponent` property has the following edge cases:

     - If `x` is zero, then `x.exponent` is `Int.min`.
     - If `x` is +/-infinity or NaN, then `x.exponent` is `Int.max`

     - Note: This documentation comment was inherited from `FloatingPoint`.
     */
    @inlinable
    public var exponent: Int {
        if !isFinite { return .max }
        if isZero { return .min }

        let provisional = Int(exponentBitPattern) - Int(Half.exponentBias)
        if isNormal { return provisional }

        let shift = Half.significandBitCount - Int(significandBitPattern._binaryLogarithm())
        return provisional + 1 - shift
    }

    /**
     A Boolean value indicating whether the instance's representation is in
     its canonical form.

     The [IEEE 754 specification][spec] defines a *canonical*, or preferred,
     encoding of a floating-point value. On platforms that fully support
     IEEE 754, every `Float` or `Double` value is canonical, but
     non-canonical values can exist on other platforms or for other types.
     Some examples:

     - On platforms that flush subnormal numbers to zero (such as armv7
       with the default floating-point environment), Swift interprets
       subnormal `Float` and `Double` values as non-canonical zeros.
       (In Swift 5.1 and earlier, `isCanonical` is `true` for these
       values, which is the incorrect value.)

     - On i386 and x86_64, `Float80` has a number of non-canonical
       encodings. "Pseudo-NaNs", "pseudo-infinities", and "unnormals" are
       interpreted as non-canonical NaN encodings. "Pseudo-denormals" are
       interpreted as non-canonical encodings of subnormal values.

     - Decimal floating-point types admit a large number of non-canonical
       encodings. Consult the IEEE 754 standard for additional details.

     [spec]: http://ieeexplore.ieee.org/servlet/opac?punumber=4610933

     - Note: This documentation comment was inherited from `FloatingPoint`.
     */
    @inlinable
    public var isCanonical: Bool {
        #if arch(arm)
        if exponentBitPattern == 0 && significandBitPattern != 0 {
            return false
        }
        #endif

        return true
    }

    /**
     A Boolean value indicating whether this instance is finite.

     All values other than NaN and infinity are considered finite, whether
     normal or subnormal.  For NaN, both `isFinite` and `isInfinite` are false.

     - Note: This documentation comment was inherited from `FloatingPoint`.
     */
    @inlinable @inline(__always)
    public var isFinite: Bool {
        return exponentBitPattern < Half.infinityExponent
    }

    /**
     A Boolean value indicating whether the instance is infinite.

     For NaN, both `isFinite` and `isInfinite` are false.

     - Note: This documentation comment was inherited from `FloatingPoint`.
     */
    @inlinable @inline(__always)
    public var isInfinite: Bool {
        return !isFinite && significandBitPattern == 0
    }

    /**
     A Boolean value indicating whether the instance is NaN ("not a number").

     Because NaN is not equal to any value, including NaN, use this property
     instead of the equal-to operator (`==`) or not-equal-to operator (`!=`)
     to test whether a value is or is not NaN. For example:

         let x = 0.0
         let y = x * .infinity
         // y is a NaN

         // Comparing with the equal-to operator never returns 'true'
         print(x == Double.nan)
         // Prints "false"
         print(y == Double.nan)
         // Prints "false"

         // Test with the 'isNaN' property instead
         print(x.isNaN)
         // Prints "false"
         print(y.isNaN)
         // Prints "true"

     This property is `true` for both quiet and signaling NaNs.

     - Note: This documentation comment was inherited from `FloatingPoint`.
     */
    @inlinable @inline(__always)
    public var isNaN: Bool {
        return !isFinite && significandBitPattern != 0
    }

    /**
     A Boolean value indicating whether this instance is normal.

     A *normal* value is a finite number that uses the full precision
     available to values of a type. Zero is neither a normal nor a subnormal
     number.

     - Note: This documentation comment was inherited from `FloatingPoint`.
     */
    @inlinable @inline(__always)
    public var isNormal: Bool {
        return exponentBitPattern > 0 && isFinite
    }

    /**
     A Boolean value indicating whether the instance is a signaling NaN.

     Signaling NaNs typically raise the Invalid flag when used in general
     computing operations.

     - Note: This documentation comment was inherited from `FloatingPoint`.
     */
    @inlinable @inline(__always)
    public var isSignalingNaN: Bool {
        return isNaN && (significandBitPattern & Half.quietNaNMask) == 0
    }

    /**
     A Boolean value indicating whether the instance is subnormal.

     A *subnormal* value is a nonzero number that has a lesser magnitude than
     the smallest normal number. Subnormal values don't use the full
     precision available to values of a type.

     Zero is neither a normal nor a subnormal number. Subnormal numbers are
     often called *denormal* or *denormalized*---these are different names
     for the same concept.

     - Note: This documentation comment was inherited from `FloatingPoint`.
     */
    @inlinable @inline(__always)
    public var isSubnormal: Bool {
        return exponentBitPattern == 0 && significandBitPattern != 0
    }

    /**
     A Boolean value indicating whether the instance is equal to zero.

     The `isZero` property of a value `x` is `true` when `x` represents either
     `-0.0` or `+0.0`. `x.isZero` is equivalent to the following comparison:
     `x == 0.0`.

         let x = -0.0
         x.isZero        // true
         x == 0.0        // true

     - Note: This documentation comment was inherited from `FloatingPoint`.
     */
    @inlinable @inline(__always)
    public var isZero: Bool {
        return exponentBitPattern == 0 && significandBitPattern == 0
    }

    /**
     The least representable value that compares greater than this value.

     For any finite value `x`, `x.nextUp` is greater than `x`. For `nan` or
     `infinity`, `x.nextUp` is `x` itself. The following special cases also
     apply:

     - If `x` is `-infinity`, then `x.nextUp` is `-greatestFiniteMagnitude`.
     - If `x` is `-leastNonzeroMagnitude`, then `x.nextUp` is `-0.0`.
     - If `x` is zero, then `x.nextUp` is `leastNonzeroMagnitude`.
     - If `x` is `greatestFiniteMagnitude`, then `x.nextUp` is `infinity`.

     - Note: This documentation comment was inherited from `FloatingPoint`.
     */
    @inlinable
    public var nextUp: Half {
        let next = self + 0

        #if arch(arm)
        // On arm, treat subnormal values as zero.
        if next == 0 { return .leastNonzeroMagnitude }
        if next == -.leastNonzeroMagnitude { return -0.0 }
        #endif

        if next < .infinity {
            let increment = Int16(bitPattern: next.bitPattern) &>> 15 | 1
            let bitPattern = next.bitPattern &+ UInt16(bitPattern: increment)
            return Half(bitPattern: bitPattern)
        }

        return next
    }

    /**
     The sign of the floating-point value.

     The `sign` property is `.minus` if the value's signbit is set, and
     `.plus` otherwise. For example:

         let x = -33.375
         // x.sign == .minus

     Don't use this property to check whether a floating point value is
     negative. For a value `x`, the comparison `x.sign == .minus` is not
     necessarily the same as `x < 0`. In particular, `x.sign == .minus` if
     `x` is -0, and while `x < 0` is always `false` if `x` is NaN, `x.sign`
     could be either `.plus` or `.minus`.

     - Note: This documentation comment was inherited from `FloatingPoint`.
     */
    @inlinable
    public var sign: FloatingPointSign {
        let shift = Half.significandBitCount + Half.exponentBitCount
        // swiftlint:disable force_unwrapping
        return FloatingPointSign(rawValue: Int(bitPattern &>> UInt16(shift)))!
        // swiftlint:enable force_unwrapping
    }

    /**
     The significand of the floating-point value.

     The magnitude of a floating-point value `x` of type `F` can be calculated
     by using the following formula, where `**` is exponentiation:

         let magnitude = x.significand * F.radix ** x.exponent

     In the next example, `y` has a value of `21.5`, which is encoded as
     `1.34375 * 2 ** 4`. The significand of `y` is therefore 1.34375.

         let y: Half = 21.5
         // y.significand == 1.34375
         // y.exponent == 4
         // Half.radix == 2

     If a type's radix is 2, then for finite nonzero numbers, the significand
     is in the range `1.0 ..< 2.0`. For other values of `x`, `x.significand`
     is defined as follows:

     - If `x` is zero, then `x.significand` is 0.0.
     - If `x` is infinite, then `x.significand` is infinity.
     - If `x` is NaN, then `x.significand` is NaN.

     - Note: This documentation comment was inherited from `FloatingPoint`.
     */
    @inlinable
    public var significand: Half {
        if isNaN { return self }
        if isNormal {
            return Half(sign: .plus, exponentBitPattern: Half.exponentBias, significandBitPattern: significandBitPattern)
        }

        if isSubnormal {
            let shift = Half.significandBitCount - Int(significandBitPattern._binaryLogarithm())
            return Half(sign: .plus, exponentBitPattern: Half.exponentBias, significandBitPattern: significandBitPattern &<< shift)
        }

        return Half(sign: .plus, exponentBitPattern: exponentBitPattern, significandBitPattern: 0)
    }

    /**
     The unit in the last place of this value.

     This is the unit of the least significant digit in this value's
     significand. For most numbers `x`, this is the difference between `x`
     and the next greater (in magnitude) representable number. There are some
     edge cases to be aware of:

     - If `x` is not a finite number, then `x.ulp` is NaN.
     - If `x` is very small in magnitude, then `x.ulp` may be a subnormal
       number. If a type does not support subnormals, `x.ulp` may be rounded
       to zero.
     - `greatestFiniteMagnitude.ulp` is a finite number, even though the next
       greater representable value is `infinity`.

     See also the `ulpOfOne` static property.

     - Note: This documentation comment was inherited from `FloatingPoint`.
     */
    @inlinable
    public var ulp: Half {
        guard isFinite else { return .nan }
        if isNormal {
            let bitPattern = self.bitPattern & Half.infinity.bitPattern
            return Half(bitPattern: bitPattern) * .ulpOfOne
        }

        return .leastNormalMagnitude * .ulpOfOne
    }

    //

    /**
     The greatest finite number representable by this type.

     This value compares greater than or equal to all finite numbers, but less
     than `infinity`.

     This value corresponds to type-specific C macros such as `FLT_MAX` and
     `DBL_MAX`. The naming of those macros is slightly misleading, because
     `infinity` is greater than this value.

     - Note: This documentation comment was inherited from `FloatingPoint`.
     */
    @inlinable
    public static var greatestFiniteMagnitude: Half {
        return Half(bitPattern: 0x7BFF)
    }

    /**
     Positive infinity.

     Infinity compares greater than all finite numbers and equal to other
     infinite values.

         let x = Half.greatestFiniteMagnitude
         let y = x * 2
         // y == Half.infinity
         // y > x

     - Note: This documentation comment was inherited from `FloatingPoint`.
     */
    @inlinable
    public static var infinity: Half {
        return Half(bitPattern: 0x7C00)
    }

    /**
     The least positive number.

     This value compares less than or equal to all positive numbers, but
     greater than zero. If the type supports subnormal values,
     `leastNonzeroMagnitude` is smaller than `leastNormalMagnitude`;
     otherwise they are equal.

     - Note: This documentation comment was inherited from `FloatingPoint`.
     */
    @inlinable
    public static var leastNonzeroMagnitude: Half {
        #if arch(arm)
        return leastNormalMagnitude
        #else
        return Half(sign: .plus, exponentBitPattern: 0, significandBitPattern: 1)
        #endif
    }

    /**
     The least positive normal number.

     This value compares less than or equal to all positive normal numbers.
     There may be smaller positive numbers, but they are *subnormal*, meaning
     that they are represented with less precision than normal numbers.

     This value corresponds to type-specific C macros such as `FLT_MIN` and
     `DBL_MIN`. The naming of those macros is slightly misleading, because
     subnormals, zeros, and negative numbers are smaller than this value.

     - Note: This documentation comment was inherited from `FloatingPoint`.
     */
    @inlinable
    public static var leastNormalMagnitude: Half {
        return Half(sign: .plus, exponentBitPattern: 1, significandBitPattern: 0)
    }

    /**
     A quiet NaN ("not a number").

     A NaN compares not equal, not greater than, and not less than every
     value, including itself. Passing a NaN to an operation generally results
     in NaN.

         let x = 1.21
         // x > Double.nan == false
         // x < Double.nan == false
         // x == Double.nan == false

     Because a NaN always compares not equal to itself, to test whether a
     floating-point value is NaN, use its `isNaN` property instead of the
     equal-to operator (`==`). In the following example, `y` is NaN.

         let y = x + Half.nan
         print(y == Half.nan)
         // Prints "false"
         print(y.isNaN)
         // Prints "true"

     - Note: This documentation comment was inherited from `FloatingPoint`.
     */
    @inlinable
    public static var nan: Half {
        return Half(_half_nan())
    }

    /**
     The mathematical constant pi.

     This value should be rounded toward zero to keep user computations with
     angles from inadvertently ending up in the wrong quadrant. A type that
     conforms to the `FloatingPoint` protocol provides the value for `pi` at
     its best possible precision.

         print(Half.pi)
         // Prints "3.140625"

     - Note: This documentation comment was inherited from `FloatingPoint`.
     */
    @inlinable
    public static var pi: Half {
        return Half(_half_pi())
    }

    /**
     A signaling NaN ("not a number").

     The default IEEE 754 behavior of operations involving a signaling NaN is
     to raise the Invalid flag in the floating-point environment and return a
     quiet NaN.

     Operations on types conforming to the `FloatingPoint` protocol should
     support this behavior, but they might also support other options. For
     example, it would be reasonable to implement alternative operations in
     which operating on a signaling NaN triggers a runtime error or results
     in a diagnostic for debugging purposes. Types that implement alternative
     behaviors for a signaling NaN must document the departure.

     Other than these signaling operations, a signaling NaN behaves in the
     same manner as a quiet NaN.

     - Note: This documentation comment was inherited from `FloatingPoint`.
     */
    @inlinable
    public static var signalingNaN: Half {
        return Half(nan: 0, signaling: true)
    }

    /**
     The unit in the last place of 1.0.

     The positive difference between 1.0 and the next greater representable
     number. `ulpOfOne` corresponds to the value represented by the C macros
     `FLT_EPSILON`, `DBL_EPSILON`, etc, and is sometimes called *epsilon* or
     *machine epsilon*. Swift deliberately avoids using the term "epsilon"
     because:

     - Historically "epsilon" has been used to refer to several different
       concepts in different languages, leading to confusion and bugs.

     - The name "epsilon" suggests that this quantity is a good tolerance to
       choose for approximate comparisons, but it is almost always unsuitable
       for that purpose.

     See also the `ulp` member property.

     - Note: This documentation comment was inherited from `FloatingPoint`.
     */
    @inlinable
    public static var ulpOfOne: Half {
        return Half(_half_epsilon())
    }

    //

    /**
     Adds the product of the two given values to this value in place, computed
     without intermediate rounding.

     - Parameters:
       - lhs: One of the values to multiply before adding to this value.
       - rhs: The other value to multiply.

     - Note: This documentation comment was inherited from `FloatingPoint`.
     */
    @_transparent
    public mutating func addProduct(_ lhs: Half, _ rhs: Half) {
        _value = _half_fma(_value, lhs._value, rhs._value)
    }

    /**
     Replaces this value with the remainder of itself divided by the given
     value.

     For two finite values `x` and `y`, the remainder `r` of dividing `x` by
     `y` satisfies `x == y * q + r`, where `q` is the integer nearest to
     `x / y`. If `x / y` is exactly halfway between two integers, `q` is
     chosen to be even. Note that `q` is *not* `x / y` computed in
     floating-point arithmetic, and that `q` may not be representable in any
     available integer type.

     The following example calculates the remainder of dividing 8.625 by 0.75:

         var x = 8.625
         print(x / 0.75)
         // Prints "11.5"

         let q = (x / 0.75).rounded(.toNearestOrEven)
         // q == 12.0
         x.formRemainder(dividingBy: 0.75)
         // x == -0.375

         let x1 = 0.75 * q + x
         // x1 == 8.625

     If this value and `other` are finite numbers, the remainder is in the
     closed range `-abs(other / 2)...abs(other / 2)`. The
     `formRemainder(dividingBy:)` method is always exact.

     - Parameters:
       - other: The value to use when dividing this value.

     - Note: This documentation comment was inherited from `FloatingPoint`.
     */
    @inlinable @inline(__always)
    public mutating func formRemainder(dividingBy other: Half) {
        self = Half(Float(self).remainder(dividingBy: Float(other)))
    }

    /**
     Replaces this value with its square root, rounded to a representable value.

     - Note: This documentation comment was inherited from `FloatingPoint`.
     */
    @_transparent
    public mutating func formSquareRoot() {
        _value = _half_sqrt(_value)
    }

    /**
     Replaces this value with the remainder of itself divided by the given
     value using truncating division.

     Performing truncating division with floating-point values results in a
     truncated integer quotient and a remainder. For values `x` and `y` and
     their truncated integer quotient `q`, the remainder `r` satisfies
     `x == y * q + r`.

     The following example calculates the truncating remainder of dividing
     8.625 by 0.75:

         var x = 8.625
         print(x / 0.75)
         // Prints "11.5"

         let q = (x / 0.75).rounded(.towardZero)
         // q == 11.0
         x.formTruncatingRemainder(dividingBy: 0.75)
         // x == 0.375

         let x1 = 0.75 * q + x
         // x1 == 8.625

     If this value and `other` are both finite numbers, the truncating
     remainder has the same sign as this value and is strictly smaller in
     magnitude than `other`. The `formTruncatingRemainder(dividingBy:)`
     method is always exact.

     - Parameters:
       - other: The value to use when dividing this value.

     - Note: This documentation comment was inherited from `FloatingPoint`.
     */
    @inlinable @inline(__always)
    public mutating func formTruncatingRemainder(dividingBy other: Half) {
        self = Half(Float(self).truncatingRemainder(dividingBy: Float(other)))
    }

    /**
     Returns a Boolean value indicating whether this instance is equal to the
     given value.

     This method serves as the basis for the equal-to operator (`==`) for
     floating-point values. When comparing two values with this method, `-0`
     is equal to `+0`. NaN is not equal to any value, including itself. For
     example:

         let x = 15.0
         x.isEqual(to: 15.0)
         // true
         x.isEqual(to: .nan)
         // false
         Double.nan.isEqual(to: .nan)
         // false

     The `isEqual(to:)` method implements the equality predicate defined by
     the [IEEE 754 specification][spec].

     [spec]: http://ieeexplore.ieee.org/servlet/opac?punumber=4610933

     - Parameters:
       - other: The value to compare with this value.

     - Returns: `true` if `other` has the same value as this instance;
       otherwise, `false`. If either this value or `other` is NaN, the result
       of this method is `false`.

     - Note: This documentation comment was inherited from `FloatingPoint`.
     */
    @_transparent
    public func isEqual(to other: Half) -> Bool {
        return Bool(_half_equal(self._value, other._value))
    }

    /**
     Returns a Boolean value indicating whether this instance is less than the
     given value.

     This method serves as the basis for the less-than operator (`<`) for
     floating-point values. Some special cases apply:

     - Because NaN compares not less than nor greater than any value, this
       method returns `false` when called on NaN or when NaN is passed as
       `other`.
     - `-infinity` compares less than all values except for itself and NaN.
     - Every value except for NaN and `+infinity` compares less than
       `+infinity`.

         let x = 15.0
         x.isLess(than: 20.0)
         // true
         x.isLess(than: .nan)
         // false
         Double.nan.isLess(than: x)
         // false

     The `isLess(than:)` method implements the less-than predicate defined by
     the [IEEE 754 specification][spec].

     [spec]: http://ieeexplore.ieee.org/servlet/opac?punumber=4610933

     - Parameter other: The value to compare with this value.
     - Returns: `true` if this value is less than `other`; otherwise, `false`.
       If either this value or `other` is NaN, the result of this method is
       `false`.

     - Note: This documentation comment was inherited from `FloatingPoint`.
     */
    @_transparent
    public func isLess(than other: Half) -> Bool {
        return Bool(_half_lt(self._value, other._value))
    }

    /**
     Returns a Boolean value indicating whether this instance is less than or
     equal to the given value.

     This method serves as the basis for the less-than-or-equal-to operator
     (`<=`) for floating-point values. Some special cases apply:

     - Because NaN is incomparable with any value, this method returns `false`
       when called on NaN or when NaN is passed as `other`.
     - `-infinity` compares less than or equal to all values except NaN.
     - Every value except NaN compares less than or equal to `+infinity`.

         let x = 15.0
         x.isLessThanOrEqualTo(20.0)
         // true
         x.isLessThanOrEqualTo(.nan)
         // false
         Double.nan.isLessThanOrEqualTo(x)
         // false

     The `isLessThanOrEqualTo(_:)` method implements the less-than-or-equal
     predicate defined by the [IEEE 754 specification][spec].

     [spec]: http://ieeexplore.ieee.org/servlet/opac?punumber=4610933

     - Parameter other: The value to compare with this value.
     - Returns: `true` if `other` is greater than this value; otherwise,
       `false`. If either this value or `other` is NaN, the result of this
       method is `false`.

     - Note: This documentation comment was inherited from `FloatingPoint`.
     */
    @_transparent
    public func isLessThanOrEqualTo(_ other: Half) -> Bool {
        return Bool(_half_lte(self._value, other._value))
    }

    /**
     Rounds the value to an integral value using the specified rounding rule.

     The following example rounds a value using four different rounding rules:

         // Equivalent to the C 'round' function:
         var w = 6.5
         w.round(.toNearestOrAwayFromZero)
         // w == 7.0

         // Equivalent to the C 'trunc' function:
         var x = 6.5
         x.round(.towardZero)
         // x == 6.0

         // Equivalent to the C 'ceil' function:
         var y = 6.5
         y.round(.up)
         // y == 7.0

         // Equivalent to the C 'floor' function:
         var z = 6.5
         z.round(.down)
         // z == 6.0

     For more information about the available rounding rules, see the
     `FloatingPointRoundingRule` enumeration. To round a value using the
     default "schoolbook rounding", you can use the shorter `round()` method
     instead.

         var w1 = 6.5
         w1.round()
         // w1 == 7.0

     - Parameter:
       - rule: The rounding rule to use.

     - Note: This documentation comment was inherited from `FloatingPoint`.
     */
    @_transparent
    public mutating func round(_ rule: FloatingPointRoundingRule) {
        self = Half(Float(self).rounded(rule))
    }

    //

    /**
     Returns the quotient of dividing the first value by the second, rounded
     to a representable value.

     The division operator (`/`) calculates the quotient of the division if
     `rhs` is nonzero. If `rhs` is zero, the result of the division is
     infinity, with the sign of the result matching the sign of `lhs`.

         let x = 16.875
         let y = x / 2.25
         // y == 7.5

         let z = x / 0
         // z.isInfinite == true

     The `/` operator implements the division operation defined by the [IEEE
     754 specification][spec].

     [spec]: http://ieeexplore.ieee.org/servlet/opac?punumber=4610933

     - Parameters:
       - lhs: The value to divide.
       - rhs: The value to divide `lhs` by.

     - Note: This documentation comment was inherited from `FloatingPoint`.
     */
    @_transparent
    public static func / (lhs: Half, rhs: Half) -> Half {
        return Half(_half_div(lhs._value, rhs._value))
    }

    /**
     Divides the first value by the second and stores the quotient in the
     left-hand-side variable, rounding to a representable value.

     - Parameters:
       - lhs: The value to divide.
       - rhs: The value to divide `lhs` by.

     - Note: This documentation comment was inherited from `FloatingPoint`.
     */
    @_transparent
    public static func /= (lhs: inout Half, rhs: Half) {
        lhs._value = _half_div(lhs._value, rhs._value)
    }
}

// MARK: - Hashable Protocol Conformance

extension Half: Hashable {

    // swiftlint:disable legacy_hashing
    /**
     The hash value.

     Hash values are not guaranteed to be equal across different executions of your
     program. Do not save hash values to use during a future execution.

     - Important: `hashValue` is deprecated as a `Hashable` requirement. To conform
       to `Hashable`, implement the `hash(into:)` requirement instead.

     - Note: This documentation comment was inherited from `Hashable`.
     */
    @inlinable
    public var hashValue: Int {
        var hasher = Hasher()
        self.hash(into: &hasher)
        return hasher.finalize()
    }
    // swiftlint:enable legacy_hashing

    /**
     Hashes the essential components of this value by feeding them into the given
     hasher.

     Implement this method to conform to the Hashable protocol. The components used
     for hashing must be the same as the components compared in your type’s ==
     operator implementation. Call `hasher.combine(_:)` with each of these
     components.

     - Parameters:
       - hasher: The hasher to use when combining the components of this instance.

     - Important: Never call `finalize()` on hasher. Doing so may become a
       compile-time error in the future.

     - Note: This documentation comment was inherited from `Hashable`.
     */
    @inlinable
    public func hash(into hasher: inout Hasher) {
        var value = self
        if isZero {
            value = 0 // to reconcile -0.0 and +0.0
        }

        hasher.combine(value.bitPattern)
    }
}

// MARK: - Strideable Protocol Conformance

extension Half: Strideable {

    /**
     Returns the distance from this value to the given value, expressed as a
     stride.

     If this type's `Stride` type conforms to `BinaryInteger`, then for two
     values `x` and `y`, and a distance `n = x.distance(to: y)`,
     `x.advanced(by: n) == y`. Using this method with types that have a
     noninteger `Stride` may result in an approximation.

     - Parameters:
       - other: The value to calculate the distance to.

     - Returns: The distance from this value to `other`.

     - Complexity: O(1)

     - Note: This documentation comment was inherited from `Strideable`.
     */
    @_transparent
    public func distance(to other: Half) -> Half {
        return other - self
    }

    /**
     Returns a value that is offset the specified distance from this value.

     Use the `advanced(by:)` method in generic code to offset a value by a
     specified distance. If you're working directly with numeric values, use
     the addition operator (`+`) instead of this method.

         func addOne<T: Strideable>(to x: T) -> T
             where T.Stride: ExpressibleByIntegerLiteral
         {
             return x.advanced(by: 1)
         }

         let x = addOne(to: 5)
         // x == 6
         let y = addOne(to: 3.5)
         // y = 4.5

     If this type's `Stride` type conforms to `BinaryInteger`, then for a
     value `x`, a distance `n`, and a value `y = x.advanced(by: n)`,
     `x.distance(to: y) == n`. Using this method with types that have a
     noninteger `Stride` may result in an approximation. If the result of
     advancing by `n` is not representable as a value of this type, then a
     runtime error may occur.

     - Parameters:
       - amount: The distance to advance this value.

     - Returns: A value that is offset from this value by `n`.

     - Complexity: O(1)

     - Note: This documentation comment was inherited from `Strideable`.
     */
    @_transparent
    public func advanced(by amount: Half) -> Half {
        return self + amount
    }
}

// MARK: - SignedNumeric Protocol Conformance

extension Half: SignedNumeric {

    /**
     Replaces this value with its additive inverse.

     The result is always exact. This example uses the `negate()` method to
     negate the value of the variable `x`:

         var x = 21.5
         x.negate()
         // x == -21.5

     - Note: This documentation comment was inherited from `FloatingPoint`.
     */
    @_transparent
    public mutating func negate() {
        _value = _half_neg(_value)
    }

    /**
     Calculates the additive inverse of a value.

     The unary minus operator (prefix `-`) calculates the negation of its
     operand. The result is always exact.

         let x = 21.5
         let y = -x
         // y == -21.5

     - Parameters:
       - operand: The value to negate.

     - Note: This documentation comment was inherited from `FloatingPoint`.
     */
    @_transparent
    public static prefix func - (value: Half) -> Half {
        return Half(_half_neg(value._value))
    }
}

// MARK: - Numeric Protocol Conformance

extension Half: Numeric {

    @inlinable @inline(__always)
    public var magnitude: Half {
        return Half(_half_abs(_value))
    }

    /**
     Creates a new value, if the given integer can be represented exactly.

     If the given integer cannot be represented exactly, the result is `nil`.

     - Parameters:
       - value: The integer to convert to a floating-point value.

     - Note: This documentation comment was inherited from `FloatingPoint`.
     */
    @inlinable @inline(__always)
    public init?<Source>(exactly value: Source) where Source: BinaryInteger {
        self.init(value)

        if isInfinite || isNaN || Source(self) != value {
            return nil
        }
    }

    /**
     Multiplies two values and produces their product, rounding to a
     representable value.

     The multiplication operator (`*`) calculates the product of its two
     arguments. For example:

         let x = 7.5
         let y = x * 2.25
         // y == 16.875

     The `*` operator implements the multiplication operation defined by the
     [IEEE 754 specification][spec].

     [spec]: http://ieeexplore.ieee.org/servlet/opac?punumber=4610933

     - Parameters:
       - lhs: The first value to multiply.
       - rhs: The second value to multiply.

     - Note: This documentation comment was inherited from `FloatingPoint`.
     */
    @_transparent
    public static func * (lhs: Half, rhs: Half) -> Half {
        return Half(_half_mul(lhs._value, rhs._value))
    }

    /**
     Multiplies two values and stores the result in the left-hand-side
     variable, rounding to a representable value.

     - Parameters:
       - lhs: The first value to multiply.
       - rhs: The second value to multiply.

     - Note: This documentation comment was inherited from `FloatingPoint`.
     */
    @_transparent
    public static func *= (lhs: inout Half, rhs: Half) {
        lhs._value = _half_mul(lhs._value, rhs._value)
    }
}

// MARK: - ExpressibleByIntegerLiteral Protocol Conformance

extension Half: ExpressibleByIntegerLiteral {

    /**
     Creates an instance initialized to the specified integer value.

     Do not call this initializer directly. Instead, initialize a variable or
     constant using an integer literal. For example:

         let x = 23

     In this example, the assignment to the `x` constant calls this integer
     literal initializer behind the scenes.

     - Parameters:
       - value: The value to create.

     - Note: This documentation comment was inherited from
       `ExpressibleByIntegerLiteral`.
     */
    @_transparent
    public init(integerLiteral value: Int64) {
        self = Half(value)
    }
}

// MARK: - AdditiveArithmetic Protocol Conformance

extension Half: AdditiveArithmetic {

    /**
     Adds two values and produces their sum, rounded to a
     representable value.

     The addition operator (`+`) calculates the sum of its two arguments. For
     example:

         let x = 1.5
         let y = x + 2.25
         // y == 3.75

     The `+` operator implements the addition operation defined by the
     [IEEE 754 specification][spec].

     [spec]: http://ieeexplore.ieee.org/servlet/opac?punumber=4610933

     - Parameters:
       - lhs: The first value to add.
       - rhs: The second value to add.

     - Note: This documentation comment was inherited from `FloatingPoint`.
     */
    @_transparent
    public static func + (lhs: Half, rhs: Half) -> Half {
        return Half(_half_add(lhs._value, rhs._value))
    }

    /**
     Adds two values and stores the result in the left-hand-side variable,
     rounded to a representable value.

     - Parameters:
       - lhs: The first value to add.
       - rhs: The second value to add.

     - Note: This documentation comment was inherited from `FloatingPoint`.
     */
    @_transparent
    public static func += (lhs: inout Half, rhs: Half) {
        lhs._value = _half_add(lhs._value, rhs._value)
    }

    /**
     Subtracts one value from another and produces their difference, rounded
     to a representable value.

     The subtraction operator (`-`) calculates the difference of its two
     arguments. For example:

         let x = 7.5
         let y = x - 2.25
         // y == 5.25

     The `-` operator implements the subtraction operation defined by the
     [IEEE 754 specification][spec].

     [spec]: http://ieeexplore.ieee.org/servlet/opac?punumber=4610933

     - Parameters:
       - lhs: A numeric value.
       - rhs: The value to subtract from `lhs`.

     - Note: This documentation comment was inherited from `FloatingPoint`.
     */
    @_transparent
    public static func - (lhs: Half, rhs: Half) -> Half {
        return Half(_half_sub(lhs._value, rhs._value))
    }

    /**
     Subtracts the second value from the first and stores the difference in
     the left-hand-side variable, rounding to a representable value.

     - Parameters:
       - lhs: A numeric value.
       - rhs: The value to subtract from `lhs`.

     - Note: This documentation comment was inherited from `FloatingPoint`.
     */
    @_transparent
    public static func -= (lhs: inout Half, rhs: Half) {
        lhs._value = _half_sub(lhs._value, rhs._value)
    }
}

// MARK: - CustomReflectable Protocol Conformance

extension Half: CustomReflectable {

    /**
     A mirror that reflects the `Half` instance.

     - Note: This documentation comment was copied and adapted from `Double`.
     */
    @_transparent
    public var customMirror: Mirror {
        return Mirror(reflecting: Float(self))
    }
}

// MARK: - CustomPlaygroundDisplayConvertible Protocol Conformance

extension Half: CustomPlaygroundDisplayConvertible {

    /**
     A custom playground description for this instance.

     - Note: This documentation comment was inherited from
       `CustomPlaygroundDisplayConvertible`.
     */
    @_transparent
    public var playgroundDescription: Any {
        return Float(self)
    }
}
#endif // #if swift(>=5.0)
