#if SWIFT_PACKAGE
	import LDKHeaders
#endif

/// An input to a transaction.
///
/// This contains the witness, the scriptSig and the previous outpoint and represents a single
/// input to a transaction
public typealias TxIn = Bindings.TxIn

extension Bindings {


	/// An input to a transaction.
	///
	/// This contains the witness, the scriptSig and the previous outpoint and represents a single
	/// input to a transaction
	public class TxIn: NativeTypeWrapper {


		/// Set to false to suppress an individual type's deinit log statements.
		/// Only applicable when log threshold is set to `.Debug`.
		public static var enableDeinitLogging = true

		/// Set to true to suspend the freeing of this type's associated Rust memory.
		/// Should only ever be used for debugging purposes, and will likely be
		/// deprecated soon.
		public static var suspendFreedom = false

		private static var instanceCounter: UInt = 0
		internal let instanceNumber: UInt

		internal var cType: LDKTxIn?

		internal init(cType: LDKTxIn, instantiationContext: String) {
			Self.instanceCounter += 1
			self.instanceNumber = Self.instanceCounter
			self.cType = cType

			super.init(conflictAvoidingVariableName: 0, instantiationContext: instantiationContext)
		}

		internal init(cType: LDKTxIn, instantiationContext: String, anchor: NativeTypeWrapper) {
			Self.instanceCounter += 1
			self.instanceNumber = Self.instanceCounter
			self.cType = cType

			super.init(conflictAvoidingVariableName: 0, instantiationContext: instantiationContext)
			self.dangling = true
			try! self.addAnchor(anchor: anchor)
		}

		internal init(cType: LDKTxIn, instantiationContext: String, anchor: NativeTypeWrapper, dangle: Bool = false) {
			Self.instanceCounter += 1
			self.instanceNumber = Self.instanceCounter
			self.cType = cType

			super.init(conflictAvoidingVariableName: 0, instantiationContext: instantiationContext)
			self.dangling = dangle
			try! self.addAnchor(anchor: anchor)
		}


		/// Frees the witness and script_sig in a TxIn
		internal func free() {
			// native call variable prep


			// native method call
			let nativeCallResult = TxIn_free(self.cType!)

			// cleanup


			// return value (do some wrapping)
			let returnValue = nativeCallResult


			return returnValue
		}

		/// Convenience function for constructing a new TxIn
		public init(witness: [UInt8], scriptSig: [UInt8], sequence: UInt32, previousTxid: [UInt8], previousVout: UInt32)
		{
			// native call variable prep

			let witnessPrimitiveWrapper = Witness(
				value: witness, instantiationContext: "TxIn.swift::\(#function):\(#line)"
			)
			.dynamicallyDangledClone()

			let scriptSigVector = Vec_u8Z(array: scriptSig, instantiationContext: "TxIn.swift::\(#function):\(#line)")
				.dangle()

			let previousTxidPrimitiveWrapper = ThirtyTwoBytes(
				value: previousTxid, instantiationContext: "TxIn.swift::\(#function):\(#line)")


			// native method call
			let nativeCallResult = TxIn_new(
				witnessPrimitiveWrapper.cType!, scriptSigVector.cType!, sequence, previousTxidPrimitiveWrapper.cType!,
				previousVout)

			// cleanup

			// for elided types, we need this
			witnessPrimitiveWrapper.noOpRetain()

			// scriptSigVector.noOpRetain()

			// for elided types, we need this
			previousTxidPrimitiveWrapper.noOpRetain()


			/*
						// return value (do some wrapping)
						let returnValue = TxIn(cType: nativeCallResult, instantiationContext: "TxIn.swift::\(#function):\(#line)")
						*/


			self.cType = nativeCallResult

			Self.instanceCounter += 1
			self.instanceNumber = Self.instanceCounter
			super.init(conflictAvoidingVariableName: 0, instantiationContext: "TxIn.swift::\(#function):\(#line)")


		}


		/// The witness which includes any signatures required to spend a segwit output.
		public func getWitness() -> [UInt8] {
			// return value (do some wrapping)
			let returnValue = Witness(
				cType: self.cType!.witness, instantiationContext: "TxIn.swift::\(#function):\(#line)", anchor: self
			)
			.getValue()

			return returnValue
		}

		/// The script_sig which includes signatures requires to spend a pre-segwit output (or a
		/// P2SH-wrapped segwit output).
		public func getScriptSig() -> [UInt8] {
			// return value (do some wrapping)
			let returnValue = Vec_u8Z(
				cType: self.cType!.script_sig, instantiationContext: "TxIn.swift::\(#function):\(#line)", anchor: self
			)
			.getValue()

			return returnValue
		}

		/// The sequence number of the transaction input
		public func getSequence() -> UInt32 {
			// return value (do some wrapping)
			let returnValue = self.cType!.sequence

			return returnValue
		}

		/// The txid of the transaction being spent.
		public func getPreviousTxid() -> [UInt8] {
			// return value (do some wrapping)
			let returnValue = ThirtyTwoBytes(
				cType: self.cType!.previous_txid, instantiationContext: "TxIn.swift::\(#function):\(#line)",
				anchor: self
			)
			.getValue()

			return returnValue
		}

		/// The output index of the transaction being spent.
		public func getPreviousVout() -> UInt32 {
			// return value (do some wrapping)
			let returnValue = self.cType!.previous_vout

			return returnValue
		}


		deinit {
			if Bindings.suspendFreedom || Self.suspendFreedom {
				return
			}

			if !self.dangling {
				if Self.enableDeinitLogging {
					Bindings.print("Freeing TxIn \(self.instanceNumber). (Origin: \(self.instantiationContext))")
				}

				self.free()
			} else if Self.enableDeinitLogging {
				Bindings.print(
					"Not freeing TxIn \(self.instanceNumber) due to dangle. (Origin: \(self.instantiationContext))")
			}
		}


	}


}

