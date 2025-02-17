#if SWIFT_PACKAGE
	import LDKHeaders
#endif

/// A CResult_CVec_C2Tuple_ThirtyTwoBytesThirtyTwoBytesZZProbingErrorZ represents the result of a fallible operation,
/// containing a crate::c_types::derived::CVec_C2Tuple_ThirtyTwoBytesThirtyTwoBytesZZ on success and a crate::lightning_invoice::payment::ProbingError on failure.
/// `result_ok` indicates the overall state, and the contents are provided via `contents`.
public typealias Result_CVec_C2Tuple_ThirtyTwoBytesThirtyTwoBytesZZProbingErrorZ = Bindings
	.Result_CVec_C2Tuple_ThirtyTwoBytesThirtyTwoBytesZZProbingErrorZ

extension Bindings {

	/// A CResult_CVec_C2Tuple_ThirtyTwoBytesThirtyTwoBytesZZProbingErrorZ represents the result of a fallible operation,
	/// containing a crate::c_types::derived::CVec_C2Tuple_ThirtyTwoBytesThirtyTwoBytesZZ on success and a crate::lightning_invoice::payment::ProbingError on failure.
	/// `result_ok` indicates the overall state, and the contents are provided via `contents`.
	public class Result_CVec_C2Tuple_ThirtyTwoBytesThirtyTwoBytesZZProbingErrorZ: NativeTypeWrapper {


		/// Set to false to suppress an individual type's deinit log statements.
		/// Only applicable when log threshold is set to `.Debug`.
		public static var enableDeinitLogging = true

		/// Set to true to suspend the freeing of this type's associated Rust memory.
		/// Should only ever be used for debugging purposes, and will likely be
		/// deprecated soon.
		public static var suspendFreedom = false

		private static var instanceCounter: UInt = 0
		internal let instanceNumber: UInt

		internal var cType: LDKCResult_CVec_C2Tuple_ThirtyTwoBytesThirtyTwoBytesZZProbingErrorZ?

		internal init(
			cType: LDKCResult_CVec_C2Tuple_ThirtyTwoBytesThirtyTwoBytesZZProbingErrorZ, instantiationContext: String
		) {
			Self.instanceCounter += 1
			self.instanceNumber = Self.instanceCounter
			self.cType = cType

			super.init(conflictAvoidingVariableName: 0, instantiationContext: instantiationContext)
		}

		internal init(
			cType: LDKCResult_CVec_C2Tuple_ThirtyTwoBytesThirtyTwoBytesZZProbingErrorZ, instantiationContext: String,
			anchor: NativeTypeWrapper
		) {
			Self.instanceCounter += 1
			self.instanceNumber = Self.instanceCounter
			self.cType = cType

			super.init(conflictAvoidingVariableName: 0, instantiationContext: instantiationContext)
			self.dangling = true
			try! self.addAnchor(anchor: anchor)
		}

		internal init(
			cType: LDKCResult_CVec_C2Tuple_ThirtyTwoBytesThirtyTwoBytesZZProbingErrorZ, instantiationContext: String,
			anchor: NativeTypeWrapper, dangle: Bool = false
		) {
			Self.instanceCounter += 1
			self.instanceNumber = Self.instanceCounter
			self.cType = cType

			super.init(conflictAvoidingVariableName: 0, instantiationContext: instantiationContext)
			self.dangling = dangle
			try! self.addAnchor(anchor: anchor)
		}


		/// Creates a new CResult_CVec_C2Tuple_ThirtyTwoBytesThirtyTwoBytesZZProbingErrorZ in the success state.
		public class func initWithOk(o: [([UInt8], [UInt8])])
			-> Result_CVec_C2Tuple_ThirtyTwoBytesThirtyTwoBytesZZProbingErrorZ
		{
			// native call variable prep

			let oVector = Vec_C2Tuple_ThirtyTwoBytesThirtyTwoBytesZZ(
				array: o,
				instantiationContext:
					"Result_CVec_C2Tuple_ThirtyTwoBytesThirtyTwoBytesZZProbingErrorZ.swift::\(#function):\(#line)"
			)
			.dangle()


			// native method call
			let nativeCallResult = CResult_CVec_C2Tuple_ThirtyTwoBytesThirtyTwoBytesZZProbingErrorZ_ok(oVector.cType!)

			// cleanup

			// oVector.noOpRetain()


			// return value (do some wrapping)
			let returnValue = Result_CVec_C2Tuple_ThirtyTwoBytesThirtyTwoBytesZZProbingErrorZ(
				cType: nativeCallResult,
				instantiationContext:
					"Result_CVec_C2Tuple_ThirtyTwoBytesThirtyTwoBytesZZProbingErrorZ.swift::\(#function):\(#line)")


			return returnValue
		}

		/// Creates a new CResult_CVec_C2Tuple_ThirtyTwoBytesThirtyTwoBytesZZProbingErrorZ in the error state.
		public class func initWithErr(e: ProbingError)
			-> Result_CVec_C2Tuple_ThirtyTwoBytesThirtyTwoBytesZZProbingErrorZ
		{
			// native call variable prep


			// native method call
			let nativeCallResult = CResult_CVec_C2Tuple_ThirtyTwoBytesThirtyTwoBytesZZProbingErrorZ_err(
				e.danglingClone().cType!)

			// cleanup


			// return value (do some wrapping)
			let returnValue = Result_CVec_C2Tuple_ThirtyTwoBytesThirtyTwoBytesZZProbingErrorZ(
				cType: nativeCallResult,
				instantiationContext:
					"Result_CVec_C2Tuple_ThirtyTwoBytesThirtyTwoBytesZZProbingErrorZ.swift::\(#function):\(#line)")


			return returnValue
		}

		/// Frees any resources used by the CResult_CVec_C2Tuple_ThirtyTwoBytesThirtyTwoBytesZZProbingErrorZ.
		internal func free() {
			// native call variable prep


			// native method call
			let nativeCallResult = CResult_CVec_C2Tuple_ThirtyTwoBytesThirtyTwoBytesZZProbingErrorZ_free(self.cType!)

			// cleanup


			// return value (do some wrapping)
			let returnValue = nativeCallResult


			return returnValue
		}

		/// Creates a new CResult_CVec_C2Tuple_ThirtyTwoBytesThirtyTwoBytesZZProbingErrorZ which has the same data as `orig`
		/// but with all dynamically-allocated buffers duplicated in new buffers.
		internal func clone() -> Result_CVec_C2Tuple_ThirtyTwoBytesThirtyTwoBytesZZProbingErrorZ {
			// native call variable prep


			// native method call
			let nativeCallResult =
				withUnsafePointer(to: self.cType!) {
					(origPointer: UnsafePointer<LDKCResult_CVec_C2Tuple_ThirtyTwoBytesThirtyTwoBytesZZProbingErrorZ>) in
					CResult_CVec_C2Tuple_ThirtyTwoBytesThirtyTwoBytesZZProbingErrorZ_clone(origPointer)
				}


			// cleanup


			// return value (do some wrapping)
			let returnValue = Result_CVec_C2Tuple_ThirtyTwoBytesThirtyTwoBytesZZProbingErrorZ(
				cType: nativeCallResult,
				instantiationContext:
					"Result_CVec_C2Tuple_ThirtyTwoBytesThirtyTwoBytesZZProbingErrorZ.swift::\(#function):\(#line)")


			return returnValue
		}


		public func isOk() -> Bool {
			return self.cType?.result_ok == true
		}


		public func getError() -> ProbingError? {
			if self.cType?.result_ok == false {
				return ProbingError(
					cType: self.cType!.contents.err.pointee,
					instantiationContext:
						"Result_CVec_C2Tuple_ThirtyTwoBytesThirtyTwoBytesZZProbingErrorZ.swift::\(#function):\(#line)",
					anchor: self)
			}
			return nil
		}


		public func getValue() -> [([UInt8], [UInt8])]? {
			if self.cType?.result_ok == true {
				return Vec_C2Tuple_ThirtyTwoBytesThirtyTwoBytesZZ(
					cType: self.cType!.contents.result.pointee,
					instantiationContext:
						"Result_CVec_C2Tuple_ThirtyTwoBytesThirtyTwoBytesZZProbingErrorZ.swift::\(#function):\(#line)",
					anchor: self
				)
				.getValue()
			}
			return nil
		}


		internal func danglingClone() -> Result_CVec_C2Tuple_ThirtyTwoBytesThirtyTwoBytesZZProbingErrorZ {
			let dangledClone = self.clone()
			dangledClone.dangling = true
			return dangledClone
		}

		deinit {
			if Bindings.suspendFreedom || Self.suspendFreedom {
				return
			}

			if !self.dangling {
				if Self.enableDeinitLogging {
					Bindings.print(
						"Freeing Result_CVec_C2Tuple_ThirtyTwoBytesThirtyTwoBytesZZProbingErrorZ \(self.instanceNumber). (Origin: \(self.instantiationContext))"
					)
				}

				self.free()
			} else if Self.enableDeinitLogging {
				Bindings.print(
					"Not freeing Result_CVec_C2Tuple_ThirtyTwoBytesThirtyTwoBytesZZProbingErrorZ \(self.instanceNumber) due to dangle. (Origin: \(self.instantiationContext))"
				)
			}
		}


	}

}
