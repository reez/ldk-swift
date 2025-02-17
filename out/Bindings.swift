import Foundation

// #if canImport(os)
//     import os
// #endif

#if SWIFT_PACKAGE
	import LDKHeaders
#endif

#if os(Linux)
	import Glibc
#else
	import Darwin.C
#endif

open class NativeTypeWrapper: Hashable {

	enum AnchorError: Error {
		case cyclicReference
	}

	private static var globalInstanceCounter: UInt = 0
	internal let globalInstanceNumber: UInt
	internal let instantiationContext: String
	internal var dangling = false
	internal private(set) var anchors: Set<NativeTypeWrapper> = []
	internal var pointerDebugDescription: String? = nil

	init(conflictAvoidingVariableName: UInt, instantiationContext: String) {
		var instanceIndex: UInt! = nil
		Bindings.instanceIndexQueue.sync {
			Self.globalInstanceCounter += 1
			instanceIndex = Self.globalInstanceCounter
		}
		self.globalInstanceNumber = instanceIndex
		self.instantiationContext = instantiationContext
	}

	internal func addAnchor(anchor: NativeTypeWrapper) throws {
		if self.hasAnchor(candidate: anchor) {
			throw AnchorError.cyclicReference
		}
		self.anchors.insert(anchor)
	}

	internal func hasAnchor(candidate: NativeTypeWrapper) -> Bool {
		if self.anchors.count == 0 {
			return false
		}
		if self.anchors.contains(candidate) {
			return true
		}
		for currentAnchor in self.anchors {
			if currentAnchor.hasAnchor(candidate: candidate) {
				return true
			}
		}
		return false
	}

	internal func dangle(_ shouldDangle: Bool = true) -> Self {
		self.dangling = shouldDangle
		return self
	}

	internal func dangleRecursively() -> Self {
		self.dangling = true
		for currentAnchor in self.anchors {
			currentAnchor.dangleRecursively()
		}
		return self
	}

	internal func noOpRetain() {
		/* there to make sure object gets retained until after this call */
	}

	public static func == (lhs: NativeTypeWrapper, rhs: NativeTypeWrapper) -> Bool {
		return (lhs.globalInstanceNumber == rhs.globalInstanceNumber)
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(globalInstanceNumber)
	}

}

open class NativeTraitWrapper: NativeTypeWrapper {

	public func activate() -> Self {
		Bindings.cacheInstance(instance: self)
		return self
	}

	public func activateOnce() -> Self {
		Bindings.cacheInstance(instance: self)
		return self
	}

}

public class Bindings {

	fileprivate static let instanceIndexQueue = DispatchQueue(label: "org.lightningdevkit.Bindings.instanceIndexQueue")
	static var nativelyExposedInstances = [UInt: NativeTraitWrapper]()
	static var nativelyExposedInstanceReferenceCounter = [UInt: Int]()

	internal static var suspendFreedom = false

	internal static var minimumPrintSeverity: PrintSeverity = .WARNING
	// #if canImport(os)
	//     internal static let logger = os.Logger(subsystem: Bundle.main.bundleIdentifier!, category: "ldk")
	// #endif

	public enum PrintSeverity: UInt {
		case DEBUG = 0
		case WARNING = 1
		case ERROR = 2
	}

	internal class func print(_ string: String, severity: PrintSeverity = .DEBUG) {
		if severity.rawValue >= Self.minimumPrintSeverity.rawValue {
			NSLog(string)
			fflush(stdout)
		}
	}

	public class func setLogThreshold(severity: PrintSeverity) {
		Self.minimumPrintSeverity = severity
	}

	public class func cacheInstance(instance: NativeTraitWrapper, countIdempotently: Bool = false) {
		let key = instance.globalInstanceNumber

		Bindings.instanceIndexQueue.sync {
			let referenceCount = (Self.nativelyExposedInstanceReferenceCounter[key] ?? 0) + 1
			if !countIdempotently || referenceCount == 1 {
				// if we count non-idempotently, always update the counter
				// otherwise, only update the counter the first time
				Self.nativelyExposedInstanceReferenceCounter[key] = referenceCount
			}
			if referenceCount == 1 {
				print(
					"Caching global instance (key). Cached instance count: (nativelyExposedInstanceReferenceCounter.count)"
				)
				Self.nativelyExposedInstances[key] = instance
			}
		}
	}

	public class func instanceToPointer(instance: NativeTraitWrapper) -> UnsafeMutableRawPointer {
		let key = instance.globalInstanceNumber
		let pointer = UnsafeMutableRawPointer(bitPattern: key)!
		print("Caching instance (key) -> (pointer)", severity: .DEBUG)
		// don't automatically cache the trait instance
		Bindings.instanceIndexQueue.sync {
			Self.nativelyExposedInstances[instance.globalInstanceNumber] = instance
		}
		return pointer
	}

	public class func pointerToInstance<T: NativeTraitWrapper>(pointer: UnsafeRawPointer, sourceMarker: String?) -> T {
		let key = UInt(bitPattern: pointer)
		print("Looking up instance (pointer) -> (key)", severity: .DEBUG)

		var rawValue: NativeTraitWrapper! = nil
		Bindings.instanceIndexQueue.sync {
			let referenceCount = Self.nativelyExposedInstanceReferenceCounter[key] ?? 0
			if referenceCount < 1 {
				print(
					"Bad lookup: non-positive reference count for instance (key): (referenceCount)!", severity: .ERROR)
			}
			rawValue = Self.nativelyExposedInstances[key]
		}
		let value = rawValue as! T
		return value
	}

	/*
				public class func clearInstancePointers() {
					for (_, currentInstance) in Self.nativelyExposedInstances {
						currentInstance.pointerDebugDescription = nil
					}
					Self.nativelyExposedInstances.removeAll()
				}
				*/

	public class func UnsafeIntPointer_to_string(nativeType: UnsafePointer<Int8>) -> String {
		let string = String(cString: nativeType)
		return string
	}

	public class func string_to_unsafe_int8_pointer(string: String) -> UnsafePointer<Int8> {
		let count = string.utf8CString.count
		let result: UnsafeMutableBufferPointer<Int8> = UnsafeMutableBufferPointer<Int8>.allocate(capacity: count)
		_ = result.initialize(from: string.utf8CString)
		let mutablePointer = result.baseAddress!
		return UnsafePointer<Int8>(mutablePointer)
	}

	public class func string_to_unsafe_uint8_pointer(string: String) -> UnsafePointer<UInt8> {
		let stringData = string.data(using: .utf8)
		let dataMutablePointer = UnsafeMutablePointer<UInt8>.allocate(capacity: string.count)
		stringData?.copyBytes(to: dataMutablePointer, count: string.count)

		return UnsafePointer<UInt8>(dataMutablePointer)
	}


	///
	public class func ldkGetCompiledVersion() -> String {
		// native call variable prep


		// native method call
		let nativeCallResult = _ldk_get_compiled_version()

		// cleanup


		// return value (do some wrapping)
		let returnValue = Str(cType: nativeCallResult, instantiationContext: "Bindings.swift::\(#function):\(#line)")
			.getValue()


		return returnValue
	}

	///
	public class func ldkCBindingsGetCompiledVersion() -> String {
		// native call variable prep


		// native method call
		let nativeCallResult = _ldk_c_bindings_get_compiled_version()

		// cleanup


		// return value (do some wrapping)
		let returnValue = Str(cType: nativeCallResult, instantiationContext: "Bindings.swift::\(#function):\(#line)")
			.getValue()


		return returnValue
	}

	/// Creates a digital signature of a message given a SecretKey, like the node's secret.
	/// A receiver knowing the PublicKey (e.g. the node's id) and the message can be sure that the signature was generated by the caller.
	/// Signatures are EC recoverable, meaning that given the message and the signature the PublicKey of the signer can be extracted.
	public class func swiftSign(msg: [UInt8], sk: [UInt8]) -> Result_StrSecp256k1ErrorZ {
		// native call variable prep

		let msgPrimitiveWrapper = u8slice(value: msg, instantiationContext: "Bindings.swift::\(#function):\(#line)")

		let tupledSk = Bindings.arrayToUInt8Tuple32(array: sk)


		// native method call
		let nativeCallResult =
			withUnsafePointer(to: tupledSk) { (tupledSkPointer: UnsafePointer<UInt8Tuple32>) in
				sign(msgPrimitiveWrapper.cType!, tupledSkPointer)
			}


		// cleanup

		// for elided types, we need this
		msgPrimitiveWrapper.noOpRetain()


		// return value (do some wrapping)
		let returnValue = Result_StrSecp256k1ErrorZ(
			cType: nativeCallResult, instantiationContext: "Bindings.swift::\(#function):\(#line)")


		return returnValue
	}

	/// Recovers the PublicKey of the signer of the message given the message and the signature.
	public class func recoverPk(msg: [UInt8], sig: String) -> Result_PublicKeySecp256k1ErrorZ {
		// native call variable prep

		let msgPrimitiveWrapper = u8slice(value: msg, instantiationContext: "Bindings.swift::\(#function):\(#line)")

		let sigPrimitiveWrapper = Str(value: sig, instantiationContext: "Bindings.swift::\(#function):\(#line)")
			.dangle()


		// native method call
		let nativeCallResult = recover_pk(msgPrimitiveWrapper.cType!, sigPrimitiveWrapper.cType!)

		// cleanup

		// for elided types, we need this
		msgPrimitiveWrapper.noOpRetain()

		// for elided types, we need this
		sigPrimitiveWrapper.noOpRetain()


		// return value (do some wrapping)
		let returnValue = Result_PublicKeySecp256k1ErrorZ(
			cType: nativeCallResult, instantiationContext: "Bindings.swift::\(#function):\(#line)")


		return returnValue
	}

	/// Verifies a message was signed by a PrivateKey that derives to a given PublicKey, given a message, a signature,
	/// and the PublicKey.
	public class func swiftVerify(msg: [UInt8], sig: String, pk: [UInt8]) -> Bool {
		// native call variable prep

		let msgPrimitiveWrapper = u8slice(value: msg, instantiationContext: "Bindings.swift::\(#function):\(#line)")

		let sigPrimitiveWrapper = Str(value: sig, instantiationContext: "Bindings.swift::\(#function):\(#line)")
			.dangle()

		let pkPrimitiveWrapper = PublicKey(value: pk, instantiationContext: "Bindings.swift::\(#function):\(#line)")


		// native method call
		let nativeCallResult = verify(msgPrimitiveWrapper.cType!, sigPrimitiveWrapper.cType!, pkPrimitiveWrapper.cType!)

		// cleanup

		// for elided types, we need this
		msgPrimitiveWrapper.noOpRetain()

		// for elided types, we need this
		sigPrimitiveWrapper.noOpRetain()

		// for elided types, we need this
		pkPrimitiveWrapper.noOpRetain()


		// return value (do some wrapping)
		let returnValue = nativeCallResult


		return returnValue
	}

	/// Construct the invoice's HRP and signatureless data into a preimage to be hashed.
	public class func constructInvoicePreimage(hrpBytes: [UInt8], dataWithoutSignature: [UInt8]) -> [UInt8] {
		// native call variable prep

		let hrpBytesPrimitiveWrapper = u8slice(
			value: hrpBytes, instantiationContext: "Bindings.swift::\(#function):\(#line)")

		let dataWithoutSignatureVector = Vec_U5Z(
			array: dataWithoutSignature, instantiationContext: "Bindings.swift::\(#function):\(#line)"
		)
		.dangle()


		// native method call
		let nativeCallResult = construct_invoice_preimage(
			hrpBytesPrimitiveWrapper.cType!, dataWithoutSignatureVector.cType!)

		// cleanup

		// for elided types, we need this
		hrpBytesPrimitiveWrapper.noOpRetain()

		// dataWithoutSignatureVector.noOpRetain()


		// return value (do some wrapping)
		let returnValue = Vec_u8Z(
			cType: nativeCallResult, instantiationContext: "Bindings.swift::\(#function):\(#line)"
		)
		.getValue()


		return returnValue
	}

	/// Read previously persisted [`ChannelMonitor`]s from the store.
	public class func readChannelMonitors(
		kvStore: KVStore, entropySource: EntropySource, signerProvider: SignerProvider
	) -> Result_CVec_C2Tuple_ThirtyTwoBytesChannelMonitorZZIOErrorZ {
		// native call variable prep


		// native method call
		let nativeCallResult = read_channel_monitors(
			kvStore.activate().cType!, entropySource.activate().cType!, signerProvider.activate().cType!)

		// cleanup


		// return value (do some wrapping)
		let returnValue = Result_CVec_C2Tuple_ThirtyTwoBytesChannelMonitorZZIOErrorZ(
			cType: nativeCallResult, instantiationContext: "Bindings.swift::\(#function):\(#line)")


		return returnValue
	}

	/// Fetches the set of [`InitFeatures`] flags that are provided by or required by
	/// [`ChannelManager`].
	public class func providedInitFeatures(config: UserConfig) -> InitFeatures {
		// native call variable prep


		// native method call
		let nativeCallResult =
			withUnsafePointer(to: config.cType!) { (configPointer: UnsafePointer<LDKUserConfig>) in
				provided_init_features(configPointer)
			}


		// cleanup


		// return value (do some wrapping)
		let returnValue = InitFeatures(
			cType: nativeCallResult, instantiationContext: "Bindings.swift::\(#function):\(#line)")


		try! returnValue.addAnchor(anchor: config)
		return returnValue
	}

	/// Equivalent to [`crate::ln::channelmanager::ChannelManager::create_inbound_payment`], but no
	/// `ChannelManager` is required. Useful for generating invoices for [phantom node payments] without
	/// a `ChannelManager`.
	///
	/// `keys` is generated by calling [`NodeSigner::get_inbound_payment_key_material`] and then
	/// calling [`ExpandedKey::new`] with its result. It is recommended to cache this value and not
	/// regenerate it for each new inbound payment.
	///
	/// `current_time` is a Unix timestamp representing the current time.
	///
	/// Note that if `min_final_cltv_expiry_delta` is set to some value, then the payment will not be receivable
	/// on versions of LDK prior to 0.0.114.
	///
	/// [phantom node payments]: crate::sign::PhantomKeysManager
	/// [`NodeSigner::get_inbound_payment_key_material`]: crate::sign::NodeSigner::get_inbound_payment_key_material
	public class func swiftCreate(
		keys: ExpandedKey, minValueMsat: UInt64?, invoiceExpiryDeltaSecs: UInt32, entropySource: EntropySource,
		currentTime: UInt64, minFinalCltvExpiryDelta: UInt16?
	) -> Result_C2Tuple_ThirtyTwoBytesThirtyTwoBytesZNoneZ {
		// native call variable prep

		let minValueMsatOption = Option_u64Z(
			some: minValueMsat, instantiationContext: "Bindings.swift::\(#function):\(#line)"
		)
		.danglingClone()

		let minFinalCltvExpiryDeltaOption = Option_u16Z(
			some: minFinalCltvExpiryDelta, instantiationContext: "Bindings.swift::\(#function):\(#line)"
		)
		.danglingClone()


		// native method call
		let nativeCallResult =
			withUnsafePointer(to: keys.cType!) { (keysPointer: UnsafePointer<LDKExpandedKey>) in

				withUnsafePointer(to: entropySource.activate().cType!) {
					(entropySourcePointer: UnsafePointer<LDKEntropySource>) in
					create(
						keysPointer, minValueMsatOption.cType!, invoiceExpiryDeltaSecs, entropySourcePointer,
						currentTime, minFinalCltvExpiryDeltaOption.cType!)
				}

			}


		// cleanup


		// return value (do some wrapping)
		let returnValue = Result_C2Tuple_ThirtyTwoBytesThirtyTwoBytesZNoneZ(
			cType: nativeCallResult, instantiationContext: "Bindings.swift::\(#function):\(#line)")


		try! returnValue.addAnchor(anchor: keys)
		return returnValue
	}

	/// Equivalent to [`crate::ln::channelmanager::ChannelManager::create_inbound_payment_for_hash`],
	/// but no `ChannelManager` is required. Useful for generating invoices for [phantom node payments]
	/// without a `ChannelManager`.
	///
	/// See [`create`] for information on the `keys` and `current_time` parameters.
	///
	/// Note that if `min_final_cltv_expiry_delta` is set to some value, then the payment will not be receivable
	/// on versions of LDK prior to 0.0.114.
	///
	/// [phantom node payments]: crate::sign::PhantomKeysManager
	public class func createFromHash(
		keys: ExpandedKey, minValueMsat: UInt64?, paymentHash: [UInt8], invoiceExpiryDeltaSecs: UInt32,
		currentTime: UInt64, minFinalCltvExpiryDelta: UInt16?
	) -> Result_ThirtyTwoBytesNoneZ {
		// native call variable prep

		let minValueMsatOption = Option_u64Z(
			some: minValueMsat, instantiationContext: "Bindings.swift::\(#function):\(#line)"
		)
		.danglingClone()

		let paymentHashPrimitiveWrapper = ThirtyTwoBytes(
			value: paymentHash, instantiationContext: "Bindings.swift::\(#function):\(#line)")

		let minFinalCltvExpiryDeltaOption = Option_u16Z(
			some: minFinalCltvExpiryDelta, instantiationContext: "Bindings.swift::\(#function):\(#line)"
		)
		.danglingClone()


		// native method call
		let nativeCallResult =
			withUnsafePointer(to: keys.cType!) { (keysPointer: UnsafePointer<LDKExpandedKey>) in
				create_from_hash(
					keysPointer, minValueMsatOption.cType!, paymentHashPrimitiveWrapper.cType!, invoiceExpiryDeltaSecs,
					currentTime, minFinalCltvExpiryDeltaOption.cType!)
			}


		// cleanup

		// for elided types, we need this
		paymentHashPrimitiveWrapper.noOpRetain()


		// return value (do some wrapping)
		let returnValue = Result_ThirtyTwoBytesNoneZ(
			cType: nativeCallResult, instantiationContext: "Bindings.swift::\(#function):\(#line)")


		try! returnValue.addAnchor(anchor: keys)
		return returnValue
	}

	/// Parses an OnionV3 host and port into a [`SocketAddress::OnionV3`].
	///
	/// The host part must end with \".onion\".
	public class func parseOnionAddress(host: String, port: UInt16) -> Result_SocketAddressSocketAddressParseErrorZ {
		// native call variable prep

		let hostPrimitiveWrapper = Str(value: host, instantiationContext: "Bindings.swift::\(#function):\(#line)")
			.dangle()


		// native method call
		let nativeCallResult = parse_onion_address(hostPrimitiveWrapper.cType!, port)

		// cleanup

		// for elided types, we need this
		hostPrimitiveWrapper.noOpRetain()


		// return value (do some wrapping)
		let returnValue = Result_SocketAddressSocketAddressParseErrorZ(
			cType: nativeCallResult, instantiationContext: "Bindings.swift::\(#function):\(#line)")


		return returnValue
	}

	/// Gets the weight for an HTLC-Success transaction.
	public class func htlcSuccessTxWeight(channelTypeFeatures: ChannelTypeFeatures) -> UInt64 {
		// native call variable prep


		// native method call
		let nativeCallResult =
			withUnsafePointer(to: channelTypeFeatures.cType!) {
				(channelTypeFeaturesPointer: UnsafePointer<LDKChannelTypeFeatures>) in
				htlc_success_tx_weight(channelTypeFeaturesPointer)
			}


		// cleanup


		// return value (do some wrapping)
		let returnValue = nativeCallResult


		return returnValue
	}

	/// Gets the weight for an HTLC-Timeout transaction.
	public class func htlcTimeoutTxWeight(channelTypeFeatures: ChannelTypeFeatures) -> UInt64 {
		// native call variable prep


		// native method call
		let nativeCallResult =
			withUnsafePointer(to: channelTypeFeatures.cType!) {
				(channelTypeFeaturesPointer: UnsafePointer<LDKChannelTypeFeatures>) in
				htlc_timeout_tx_weight(channelTypeFeaturesPointer)
			}


		// cleanup


		// return value (do some wrapping)
		let returnValue = nativeCallResult


		return returnValue
	}

	/// Build the commitment secret from the seed and the commitment number
	public class func buildCommitmentSecret(commitmentSeed: [UInt8], idx: UInt64) -> [UInt8] {
		// native call variable prep

		let tupledCommitmentSeed = Bindings.arrayToUInt8Tuple32(array: commitmentSeed)


		// native method call
		let nativeCallResult =
			withUnsafePointer(to: tupledCommitmentSeed) { (tupledCommitmentSeedPointer: UnsafePointer<UInt8Tuple32>) in
				build_commitment_secret(tupledCommitmentSeedPointer, idx)
			}


		// cleanup


		// return value (do some wrapping)
		let returnValue = ThirtyTwoBytes(
			cType: nativeCallResult, instantiationContext: "Bindings.swift::\(#function):\(#line)"
		)
		.getValue()


		return returnValue
	}

	/// Build a closing transaction
	public class func buildClosingTransaction(
		toHolderValueSat: UInt64, toCounterpartyValueSat: UInt64, toHolderScript: [UInt8],
		toCounterpartyScript: [UInt8], fundingOutpoint: OutPoint
	) -> [UInt8] {
		// native call variable prep

		let toHolderScriptVector = Vec_u8Z(
			array: toHolderScript, instantiationContext: "Bindings.swift::\(#function):\(#line)"
		)
		.dangle()

		let toCounterpartyScriptVector = Vec_u8Z(
			array: toCounterpartyScript, instantiationContext: "Bindings.swift::\(#function):\(#line)"
		)
		.dangle()


		// native method call
		let nativeCallResult = build_closing_transaction(
			toHolderValueSat, toCounterpartyValueSat, toHolderScriptVector.cType!, toCounterpartyScriptVector.cType!,
			fundingOutpoint.dynamicallyDangledClone().cType!)

		// cleanup

		// toHolderScriptVector.noOpRetain()

		// toCounterpartyScriptVector.noOpRetain()


		// return value (do some wrapping)
		let returnValue = Transaction(
			cType: nativeCallResult, instantiationContext: "Bindings.swift::\(#function):\(#line)"
		)
		.getValue()


		return returnValue
	}

	/// Derives a per-commitment-transaction private key (eg an htlc key or delayed_payment key)
	/// from the base secret and the per_commitment_point.
	public class func derivePrivateKey(perCommitmentPoint: [UInt8], baseSecret: [UInt8]) -> [UInt8] {
		// native call variable prep

		let perCommitmentPointPrimitiveWrapper = PublicKey(
			value: perCommitmentPoint, instantiationContext: "Bindings.swift::\(#function):\(#line)")

		let tupledBaseSecret = Bindings.arrayToUInt8Tuple32(array: baseSecret)


		// native method call
		let nativeCallResult =
			withUnsafePointer(to: tupledBaseSecret) { (tupledBaseSecretPointer: UnsafePointer<UInt8Tuple32>) in
				derive_private_key(perCommitmentPointPrimitiveWrapper.cType!, tupledBaseSecretPointer)
			}


		// cleanup

		// for elided types, we need this
		perCommitmentPointPrimitiveWrapper.noOpRetain()


		// return value (do some wrapping)
		let returnValue = SecretKey(
			cType: nativeCallResult, instantiationContext: "Bindings.swift::\(#function):\(#line)"
		)
		.getValue()


		return returnValue
	}

	/// Derives a per-commitment-transaction public key (eg an htlc key or a delayed_payment key)
	/// from the base point and the per_commitment_key. This is the public equivalent of
	/// derive_private_key - using only public keys to derive a public key instead of private keys.
	public class func derivePublicKey(perCommitmentPoint: [UInt8], basePoint: [UInt8]) -> [UInt8] {
		// native call variable prep

		let perCommitmentPointPrimitiveWrapper = PublicKey(
			value: perCommitmentPoint, instantiationContext: "Bindings.swift::\(#function):\(#line)")

		let basePointPrimitiveWrapper = PublicKey(
			value: basePoint, instantiationContext: "Bindings.swift::\(#function):\(#line)")


		// native method call
		let nativeCallResult = derive_public_key(
			perCommitmentPointPrimitiveWrapper.cType!, basePointPrimitiveWrapper.cType!)

		// cleanup

		// for elided types, we need this
		perCommitmentPointPrimitiveWrapper.noOpRetain()

		// for elided types, we need this
		basePointPrimitiveWrapper.noOpRetain()


		// return value (do some wrapping)
		let returnValue = PublicKey(
			cType: nativeCallResult, instantiationContext: "Bindings.swift::\(#function):\(#line)"
		)
		.getValue()


		return returnValue
	}

	/// Derives a per-commitment-transaction revocation key from its constituent parts.
	///
	/// Only the cheating participant owns a valid witness to propagate a revoked
	/// commitment transaction, thus per_commitment_secret always come from cheater
	/// and revocation_base_secret always come from punisher, which is the broadcaster
	/// of the transaction spending with this key knowledge.
	public class func derivePrivateRevocationKey(
		perCommitmentSecret: [UInt8], countersignatoryRevocationBaseSecret: [UInt8]
	) -> [UInt8] {
		// native call variable prep

		let tupledPerCommitmentSecret = Bindings.arrayToUInt8Tuple32(array: perCommitmentSecret)

		let tupledCountersignatoryRevocationBaseSecret = Bindings.arrayToUInt8Tuple32(
			array: countersignatoryRevocationBaseSecret)


		// native method call
		let nativeCallResult =
			withUnsafePointer(to: tupledPerCommitmentSecret) {
				(tupledPerCommitmentSecretPointer: UnsafePointer<UInt8Tuple32>) in

				withUnsafePointer(to: tupledCountersignatoryRevocationBaseSecret) {
					(tupledCountersignatoryRevocationBaseSecretPointer: UnsafePointer<UInt8Tuple32>) in
					derive_private_revocation_key(
						tupledPerCommitmentSecretPointer, tupledCountersignatoryRevocationBaseSecretPointer)
				}

			}


		// cleanup


		// return value (do some wrapping)
		let returnValue = SecretKey(
			cType: nativeCallResult, instantiationContext: "Bindings.swift::\(#function):\(#line)"
		)
		.getValue()


		return returnValue
	}

	/// Derives a per-commitment-transaction revocation public key from its constituent parts. This is
	/// the public equivalend of derive_private_revocation_key - using only public keys to derive a
	/// public key instead of private keys.
	///
	/// Only the cheating participant owns a valid witness to propagate a revoked
	/// commitment transaction, thus per_commitment_point always come from cheater
	/// and revocation_base_point always come from punisher, which is the broadcaster
	/// of the transaction spending with this key knowledge.
	///
	/// Note that this is infallible iff we trust that at least one of the two input keys are randomly
	/// generated (ie our own).
	public class func derivePublicRevocationKey(
		perCommitmentPoint: [UInt8], countersignatoryRevocationBasePoint: [UInt8]
	) -> [UInt8] {
		// native call variable prep

		let perCommitmentPointPrimitiveWrapper = PublicKey(
			value: perCommitmentPoint, instantiationContext: "Bindings.swift::\(#function):\(#line)")

		let countersignatoryRevocationBasePointPrimitiveWrapper = PublicKey(
			value: countersignatoryRevocationBasePoint, instantiationContext: "Bindings.swift::\(#function):\(#line)")


		// native method call
		let nativeCallResult = derive_public_revocation_key(
			perCommitmentPointPrimitiveWrapper.cType!, countersignatoryRevocationBasePointPrimitiveWrapper.cType!)

		// cleanup

		// for elided types, we need this
		perCommitmentPointPrimitiveWrapper.noOpRetain()

		// for elided types, we need this
		countersignatoryRevocationBasePointPrimitiveWrapper.noOpRetain()


		// return value (do some wrapping)
		let returnValue = PublicKey(
			cType: nativeCallResult, instantiationContext: "Bindings.swift::\(#function):\(#line)"
		)
		.getValue()


		return returnValue
	}

	/// A script either spendable by the revocation
	/// key or the broadcaster_delayed_payment_key and satisfying the relative-locktime OP_CSV constrain.
	/// Encumbering a `to_holder` output on a commitment transaction or 2nd-stage HTLC transactions.
	public class func getRevokeableRedeemscript(
		revocationKey: [UInt8], contestDelay: UInt16, broadcasterDelayedPaymentKey: [UInt8]
	) -> [UInt8] {
		// native call variable prep

		let revocationKeyPrimitiveWrapper = PublicKey(
			value: revocationKey, instantiationContext: "Bindings.swift::\(#function):\(#line)")

		let broadcasterDelayedPaymentKeyPrimitiveWrapper = PublicKey(
			value: broadcasterDelayedPaymentKey, instantiationContext: "Bindings.swift::\(#function):\(#line)")


		// native method call
		let nativeCallResult = get_revokeable_redeemscript(
			revocationKeyPrimitiveWrapper.cType!, contestDelay, broadcasterDelayedPaymentKeyPrimitiveWrapper.cType!)

		// cleanup

		// for elided types, we need this
		revocationKeyPrimitiveWrapper.noOpRetain()

		// for elided types, we need this
		broadcasterDelayedPaymentKeyPrimitiveWrapper.noOpRetain()


		// return value (do some wrapping)
		let returnValue = Vec_u8Z(
			cType: nativeCallResult, instantiationContext: "Bindings.swift::\(#function):\(#line)"
		)
		.getValue()


		return returnValue
	}

	/// Returns the script for the counterparty's output on a holder's commitment transaction based on
	/// the channel type.
	public class func getCounterpartyPaymentScript(channelTypeFeatures: ChannelTypeFeatures, paymentKey: [UInt8])
		-> [UInt8]
	{
		// native call variable prep

		let paymentKeyPrimitiveWrapper = PublicKey(
			value: paymentKey, instantiationContext: "Bindings.swift::\(#function):\(#line)")


		// native method call
		let nativeCallResult =
			withUnsafePointer(to: channelTypeFeatures.cType!) {
				(channelTypeFeaturesPointer: UnsafePointer<LDKChannelTypeFeatures>) in
				get_counterparty_payment_script(channelTypeFeaturesPointer, paymentKeyPrimitiveWrapper.cType!)
			}


		// cleanup

		// for elided types, we need this
		paymentKeyPrimitiveWrapper.noOpRetain()


		// return value (do some wrapping)
		let returnValue = Vec_u8Z(
			cType: nativeCallResult, instantiationContext: "Bindings.swift::\(#function):\(#line)"
		)
		.getValue()


		return returnValue
	}

	/// Gets the witness redeemscript for an HTLC output in a commitment transaction. Note that htlc
	/// does not need to have its previous_output_index filled.
	public class func getHtlcRedeemscript(
		htlc: HTLCOutputInCommitment, channelTypeFeatures: ChannelTypeFeatures, keys: TxCreationKeys
	) -> [UInt8] {
		// native call variable prep


		// native method call
		let nativeCallResult =
			withUnsafePointer(to: htlc.cType!) { (htlcPointer: UnsafePointer<LDKHTLCOutputInCommitment>) in

				withUnsafePointer(to: channelTypeFeatures.cType!) {
					(channelTypeFeaturesPointer: UnsafePointer<LDKChannelTypeFeatures>) in

					withUnsafePointer(to: keys.cType!) { (keysPointer: UnsafePointer<LDKTxCreationKeys>) in
						get_htlc_redeemscript(htlcPointer, channelTypeFeaturesPointer, keysPointer)
					}

				}

			}


		// cleanup


		// return value (do some wrapping)
		let returnValue = Vec_u8Z(
			cType: nativeCallResult, instantiationContext: "Bindings.swift::\(#function):\(#line)"
		)
		.getValue()


		return returnValue
	}

	/// Gets the redeemscript for a funding output from the two funding public keys.
	/// Note that the order of funding public keys does not matter.
	public class func makeFundingRedeemscript(broadcaster: [UInt8], countersignatory: [UInt8]) -> [UInt8] {
		// native call variable prep

		let broadcasterPrimitiveWrapper = PublicKey(
			value: broadcaster, instantiationContext: "Bindings.swift::\(#function):\(#line)")

		let countersignatoryPrimitiveWrapper = PublicKey(
			value: countersignatory, instantiationContext: "Bindings.swift::\(#function):\(#line)")


		// native method call
		let nativeCallResult = make_funding_redeemscript(
			broadcasterPrimitiveWrapper.cType!, countersignatoryPrimitiveWrapper.cType!)

		// cleanup

		// for elided types, we need this
		broadcasterPrimitiveWrapper.noOpRetain()

		// for elided types, we need this
		countersignatoryPrimitiveWrapper.noOpRetain()


		// return value (do some wrapping)
		let returnValue = Vec_u8Z(
			cType: nativeCallResult, instantiationContext: "Bindings.swift::\(#function):\(#line)"
		)
		.getValue()


		return returnValue
	}

	/// Builds an unsigned HTLC-Success or HTLC-Timeout transaction from the given channel and HTLC
	/// parameters. This is used by [`TrustedCommitmentTransaction::get_htlc_sigs`] to fetch the
	/// transaction which needs signing, and can be used to construct an HTLC transaction which is
	/// broadcastable given a counterparty HTLC signature.
	///
	/// Panics if htlc.transaction_output_index.is_none() (as such HTLCs do not appear in the
	/// commitment transaction).
	public class func buildHtlcTransaction(
		commitmentTxid: [UInt8], feeratePerKw: UInt32, contestDelay: UInt16, htlc: HTLCOutputInCommitment,
		channelTypeFeatures: ChannelTypeFeatures, broadcasterDelayedPaymentKey: [UInt8], revocationKey: [UInt8]
	) -> [UInt8] {
		// native call variable prep

		let tupledCommitmentTxid = Bindings.arrayToUInt8Tuple32(array: commitmentTxid)

		let broadcasterDelayedPaymentKeyPrimitiveWrapper = PublicKey(
			value: broadcasterDelayedPaymentKey, instantiationContext: "Bindings.swift::\(#function):\(#line)")

		let revocationKeyPrimitiveWrapper = PublicKey(
			value: revocationKey, instantiationContext: "Bindings.swift::\(#function):\(#line)")


		// native method call
		let nativeCallResult =
			withUnsafePointer(to: tupledCommitmentTxid) { (tupledCommitmentTxidPointer: UnsafePointer<UInt8Tuple32>) in

				withUnsafePointer(to: htlc.cType!) { (htlcPointer: UnsafePointer<LDKHTLCOutputInCommitment>) in

					withUnsafePointer(to: channelTypeFeatures.cType!) {
						(channelTypeFeaturesPointer: UnsafePointer<LDKChannelTypeFeatures>) in
						build_htlc_transaction(
							tupledCommitmentTxidPointer, feeratePerKw, contestDelay, htlcPointer,
							channelTypeFeaturesPointer, broadcasterDelayedPaymentKeyPrimitiveWrapper.cType!,
							revocationKeyPrimitiveWrapper.cType!)
					}

				}

			}


		// cleanup

		// for elided types, we need this
		broadcasterDelayedPaymentKeyPrimitiveWrapper.noOpRetain()

		// for elided types, we need this
		revocationKeyPrimitiveWrapper.noOpRetain()


		// return value (do some wrapping)
		let returnValue = Transaction(
			cType: nativeCallResult, instantiationContext: "Bindings.swift::\(#function):\(#line)"
		)
		.getValue()


		return returnValue
	}

	/// Returns the witness required to satisfy and spend a HTLC input.
	public class func buildHtlcInputWitness(
		localSig: [UInt8], remoteSig: [UInt8], preimage: [UInt8]?, redeemScript: [UInt8],
		channelTypeFeatures: ChannelTypeFeatures
	) -> [UInt8] {
		// native call variable prep

		let localSigPrimitiveWrapper = ECDSASignature(
			value: localSig, instantiationContext: "Bindings.swift::\(#function):\(#line)")

		let remoteSigPrimitiveWrapper = ECDSASignature(
			value: remoteSig, instantiationContext: "Bindings.swift::\(#function):\(#line)")

		let preimageOption = Option_ThirtyTwoBytesZ(
			some: preimage, instantiationContext: "Bindings.swift::\(#function):\(#line)"
		)
		.danglingClone()

		let redeemScriptPrimitiveWrapper = u8slice(
			value: redeemScript, instantiationContext: "Bindings.swift::\(#function):\(#line)")


		// native method call
		let nativeCallResult =
			withUnsafePointer(to: channelTypeFeatures.cType!) {
				(channelTypeFeaturesPointer: UnsafePointer<LDKChannelTypeFeatures>) in
				build_htlc_input_witness(
					localSigPrimitiveWrapper.cType!, remoteSigPrimitiveWrapper.cType!, preimageOption.cType!,
					redeemScriptPrimitiveWrapper.cType!, channelTypeFeaturesPointer)
			}


		// cleanup

		// for elided types, we need this
		localSigPrimitiveWrapper.noOpRetain()

		// for elided types, we need this
		remoteSigPrimitiveWrapper.noOpRetain()

		// for elided types, we need this
		redeemScriptPrimitiveWrapper.noOpRetain()


		// return value (do some wrapping)
		let returnValue = Witness(
			cType: nativeCallResult, instantiationContext: "Bindings.swift::\(#function):\(#line)"
		)
		.getValue()


		return returnValue
	}

	/// Gets the witnessScript for the to_remote output when anchors are enabled.
	public class func getToCountersignatoryWithAnchorsRedeemscript(paymentPoint: [UInt8]) -> [UInt8] {
		// native call variable prep

		let paymentPointPrimitiveWrapper = PublicKey(
			value: paymentPoint, instantiationContext: "Bindings.swift::\(#function):\(#line)")


		// native method call
		let nativeCallResult = get_to_countersignatory_with_anchors_redeemscript(paymentPointPrimitiveWrapper.cType!)

		// cleanup

		// for elided types, we need this
		paymentPointPrimitiveWrapper.noOpRetain()


		// return value (do some wrapping)
		let returnValue = Vec_u8Z(
			cType: nativeCallResult, instantiationContext: "Bindings.swift::\(#function):\(#line)"
		)
		.getValue()


		return returnValue
	}

	/// Gets the witnessScript for an anchor output from the funding public key.
	/// The witness in the spending input must be:
	/// <BIP 143 funding_signature>
	/// After 16 blocks of confirmation, an alternative satisfying witness could be:
	/// <>
	/// (empty vector required to satisfy compliance with MINIMALIF-standard rule)
	public class func getAnchorRedeemscript(fundingPubkey: [UInt8]) -> [UInt8] {
		// native call variable prep

		let fundingPubkeyPrimitiveWrapper = PublicKey(
			value: fundingPubkey, instantiationContext: "Bindings.swift::\(#function):\(#line)")


		// native method call
		let nativeCallResult = get_anchor_redeemscript(fundingPubkeyPrimitiveWrapper.cType!)

		// cleanup

		// for elided types, we need this
		fundingPubkeyPrimitiveWrapper.noOpRetain()


		// return value (do some wrapping)
		let returnValue = Vec_u8Z(
			cType: nativeCallResult, instantiationContext: "Bindings.swift::\(#function):\(#line)"
		)
		.getValue()


		return returnValue
	}

	/// Returns the witness required to satisfy and spend an anchor input.
	public class func buildAnchorInputWitness(fundingKey: [UInt8], fundingSig: [UInt8]) -> [UInt8] {
		// native call variable prep

		let fundingKeyPrimitiveWrapper = PublicKey(
			value: fundingKey, instantiationContext: "Bindings.swift::\(#function):\(#line)")

		let fundingSigPrimitiveWrapper = ECDSASignature(
			value: fundingSig, instantiationContext: "Bindings.swift::\(#function):\(#line)")


		// native method call
		let nativeCallResult = build_anchor_input_witness(
			fundingKeyPrimitiveWrapper.cType!, fundingSigPrimitiveWrapper.cType!)

		// cleanup

		// for elided types, we need this
		fundingKeyPrimitiveWrapper.noOpRetain()

		// for elided types, we need this
		fundingSigPrimitiveWrapper.noOpRetain()


		// return value (do some wrapping)
		let returnValue = Witness(
			cType: nativeCallResult, instantiationContext: "Bindings.swift::\(#function):\(#line)"
		)
		.getValue()


		return returnValue
	}

	/// Commitment transaction numbers which appear in the transactions themselves are XOR'd with a
	/// shared secret first. This prevents on-chain observers from discovering how many commitment
	/// transactions occurred in a channel before it was closed.
	///
	/// This function gets the shared secret from relevant channel public keys and can be used to
	/// \"decrypt\" the commitment transaction number given a commitment transaction on-chain.
	public class func getCommitmentTransactionNumberObscureFactor(
		broadcasterPaymentBasepoint: [UInt8], countersignatoryPaymentBasepoint: [UInt8], outboundFromBroadcaster: Bool
	) -> UInt64 {
		// native call variable prep

		let broadcasterPaymentBasepointPrimitiveWrapper = PublicKey(
			value: broadcasterPaymentBasepoint, instantiationContext: "Bindings.swift::\(#function):\(#line)")

		let countersignatoryPaymentBasepointPrimitiveWrapper = PublicKey(
			value: countersignatoryPaymentBasepoint, instantiationContext: "Bindings.swift::\(#function):\(#line)")


		// native method call
		let nativeCallResult = get_commitment_transaction_number_obscure_factor(
			broadcasterPaymentBasepointPrimitiveWrapper.cType!, countersignatoryPaymentBasepointPrimitiveWrapper.cType!,
			outboundFromBroadcaster)

		// cleanup

		// for elided types, we need this
		broadcasterPaymentBasepointPrimitiveWrapper.noOpRetain()

		// for elided types, we need this
		countersignatoryPaymentBasepointPrimitiveWrapper.noOpRetain()


		// return value (do some wrapping)
		let returnValue = nativeCallResult


		return returnValue
	}

	/// Verifies the signature of a [`NodeAnnouncement`].
	///
	/// Returns an error if it is invalid.
	public class func verifyNodeAnnouncement(msg: NodeAnnouncement) -> Result_NoneLightningErrorZ {
		// native call variable prep


		// native method call
		let nativeCallResult =
			withUnsafePointer(to: msg.cType!) { (msgPointer: UnsafePointer<LDKNodeAnnouncement>) in
				verify_node_announcement(msgPointer)
			}


		// cleanup


		// return value (do some wrapping)
		let returnValue = Result_NoneLightningErrorZ(
			cType: nativeCallResult, instantiationContext: "Bindings.swift::\(#function):\(#line)")


		try! returnValue.addAnchor(anchor: msg)
		return returnValue
	}

	/// Verifies all signatures included in a [`ChannelAnnouncement`].
	///
	/// Returns an error if one of the signatures is invalid.
	public class func verifyChannelAnnouncement(msg: ChannelAnnouncement) -> Result_NoneLightningErrorZ {
		// native call variable prep


		// native method call
		let nativeCallResult =
			withUnsafePointer(to: msg.cType!) { (msgPointer: UnsafePointer<LDKChannelAnnouncement>) in
				verify_channel_announcement(msgPointer)
			}


		// cleanup


		// return value (do some wrapping)
		let returnValue = Result_NoneLightningErrorZ(
			cType: nativeCallResult, instantiationContext: "Bindings.swift::\(#function):\(#line)")


		try! returnValue.addAnchor(anchor: msg)
		return returnValue
	}

	/// Finds a route from us (payer) to the given target node (payee).
	///
	/// If the payee provided features in their invoice, they should be provided via the `payee` field
	/// in the given [`RouteParameters::payment_params`].
	/// Without this, MPP will only be used if the payee's features are available in the network graph.
	///
	/// Private routing paths between a public node and the target may be included in the `payee` field
	/// of [`RouteParameters::payment_params`].
	///
	/// If some channels aren't announced, it may be useful to fill in `first_hops` with the results
	/// from [`ChannelManager::list_usable_channels`]. If it is filled in, the view of these channels
	/// from `network_graph` will be ignored, and only those in `first_hops` will be used.
	///
	/// The fees on channels from us to the next hop are ignored as they are assumed to all be equal.
	/// However, the enabled/disabled bit on such channels as well as the `htlc_minimum_msat` /
	/// `htlc_maximum_msat` *are* checked as they may change based on the receiving node.
	///
	/// # Panics
	///
	/// Panics if first_hops contains channels without `short_channel_id`s;
	/// [`ChannelManager::list_usable_channels`] will never include such channels.
	///
	/// [`ChannelManager::list_usable_channels`]: crate::ln::channelmanager::ChannelManager::list_usable_channels
	/// [`Event::PaymentPathFailed`]: crate::events::Event::PaymentPathFailed
	/// [`NetworkGraph`]: crate::routing::gossip::NetworkGraph
	///
	/// Note that first_hops (or a relevant inner pointer) may be NULL or all-0s to represent None
	public class func findRoute(
		ourNodePubkey: [UInt8], routeParams: RouteParameters, networkGraph: NetworkGraph, firstHops: [ChannelDetails]?,
		logger: Logger, scorer: ScoreLookUp, scoreParams: ProbabilisticScoringFeeParameters, randomSeedBytes: [UInt8]
	) -> Result_RouteLightningErrorZ {
		// native call variable prep

		let ourNodePubkeyPrimitiveWrapper = PublicKey(
			value: ourNodePubkey, instantiationContext: "Bindings.swift::\(#function):\(#line)")

		var firstHopsVectorPointer: UnsafeMutablePointer<LDKCVec_ChannelDetailsZ>? = nil
		if let firstHops = firstHops {

			let firstHopsVector = Vec_ChannelDetailsZ(
				array: firstHops, instantiationContext: "Bindings.swift::\(#function):\(#line)"
			)
			.dangle()

			firstHopsVectorPointer = UnsafeMutablePointer<LDKCVec_ChannelDetailsZ>.allocate(capacity: 1)
			firstHopsVectorPointer!.initialize(to: firstHopsVector.cType!)
		}

		let tupledRandomSeedBytes = Bindings.arrayToUInt8Tuple32(array: randomSeedBytes)


		// native method call
		let nativeCallResult =
			withUnsafePointer(to: routeParams.cType!) { (routeParamsPointer: UnsafePointer<LDKRouteParameters>) in

				withUnsafePointer(to: networkGraph.cType!) { (networkGraphPointer: UnsafePointer<LDKNetworkGraph>) in

					withUnsafePointer(to: scorer.activate().cType!) { (scorerPointer: UnsafePointer<LDKScoreLookUp>) in

						withUnsafePointer(to: scoreParams.cType!) {
							(scoreParamsPointer: UnsafePointer<LDKProbabilisticScoringFeeParameters>) in

							withUnsafePointer(to: tupledRandomSeedBytes) {
								(tupledRandomSeedBytesPointer: UnsafePointer<UInt8Tuple32>) in
								find_route(
									ourNodePubkeyPrimitiveWrapper.cType!, routeParamsPointer, networkGraphPointer,
									firstHopsVectorPointer, logger.activate().cType!, scorerPointer, scoreParamsPointer,
									tupledRandomSeedBytesPointer)
							}

						}

					}

				}

			}


		// cleanup

		// for elided types, we need this
		ourNodePubkeyPrimitiveWrapper.noOpRetain()

		// firstHopsVector.noOpRetain()


		// return value (do some wrapping)
		let returnValue = Result_RouteLightningErrorZ(
			cType: nativeCallResult, instantiationContext: "Bindings.swift::\(#function):\(#line)")


		try! returnValue.addAnchor(anchor: routeParams)
		try! returnValue.addAnchor(anchor: networkGraph)
		try! returnValue.addAnchor(anchor: scoreParams)
		return returnValue
	}

	/// Construct a route from us (payer) to the target node (payee) via the given hops (which should
	/// exclude the payer, but include the payee). This may be useful, e.g., for probing the chosen path.
	///
	/// Re-uses logic from `find_route`, so the restrictions described there also apply here.
	public class func buildRouteFromHops(
		ourNodePubkey: [UInt8], hops: [[UInt8]], routeParams: RouteParameters, networkGraph: NetworkGraph,
		logger: Logger, randomSeedBytes: [UInt8]
	) -> Result_RouteLightningErrorZ {
		// native call variable prep

		let ourNodePubkeyPrimitiveWrapper = PublicKey(
			value: ourNodePubkey, instantiationContext: "Bindings.swift::\(#function):\(#line)")

		let hopsVector = Vec_PublicKeyZ(array: hops, instantiationContext: "Bindings.swift::\(#function):\(#line)")
			.dangle()

		let tupledRandomSeedBytes = Bindings.arrayToUInt8Tuple32(array: randomSeedBytes)


		// native method call
		let nativeCallResult =
			withUnsafePointer(to: routeParams.cType!) { (routeParamsPointer: UnsafePointer<LDKRouteParameters>) in

				withUnsafePointer(to: networkGraph.cType!) { (networkGraphPointer: UnsafePointer<LDKNetworkGraph>) in

					withUnsafePointer(to: tupledRandomSeedBytes) {
						(tupledRandomSeedBytesPointer: UnsafePointer<UInt8Tuple32>) in
						build_route_from_hops(
							ourNodePubkeyPrimitiveWrapper.cType!, hopsVector.cType!, routeParamsPointer,
							networkGraphPointer, logger.activate().cType!, tupledRandomSeedBytesPointer)
					}

				}

			}


		// cleanup

		// for elided types, we need this
		ourNodePubkeyPrimitiveWrapper.noOpRetain()

		// hopsVector.noOpRetain()


		// return value (do some wrapping)
		let returnValue = Result_RouteLightningErrorZ(
			cType: nativeCallResult, instantiationContext: "Bindings.swift::\(#function):\(#line)")


		try! returnValue.addAnchor(anchor: routeParams)
		try! returnValue.addAnchor(anchor: networkGraph)
		return returnValue
	}

	/// Creates an [`OnionMessage`] with the given `contents` for sending to the destination of
	/// `path`.
	///
	/// Returns both the node id of the peer to send the message to and the message itself.
	///
	/// Note that reply_path (or a relevant inner pointer) may be NULL or all-0s to represent None
	public class func createOnionMessage(
		entropySource: EntropySource, nodeSigner: NodeSigner, path: OnionMessagePath, contents: OnionMessageContents,
		replyPath: BlindedPath
	) -> Result_C2Tuple_PublicKeyOnionMessageZSendErrorZ {
		// native call variable prep


		// native method call
		let nativeCallResult =
			withUnsafePointer(to: entropySource.activate().cType!) {
				(entropySourcePointer: UnsafePointer<LDKEntropySource>) in

				withUnsafePointer(to: nodeSigner.activate().cType!) {
					(nodeSignerPointer: UnsafePointer<LDKNodeSigner>) in
					create_onion_message(
						entropySourcePointer, nodeSignerPointer, path.dynamicallyDangledClone().cType!,
						contents.activate().cType!, replyPath.dynamicallyDangledClone().cType!)
				}

			}


		// cleanup


		// return value (do some wrapping)
		let returnValue = Result_C2Tuple_PublicKeyOnionMessageZSendErrorZ(
			cType: nativeCallResult, instantiationContext: "Bindings.swift::\(#function):\(#line)")


		return returnValue
	}

	/// Decode one layer of an incoming [`OnionMessage`].
	///
	/// Returns either the next layer of the onion for forwarding or the decrypted content for the
	/// receiver.
	public class func peelOnionMessage(
		msg: OnionMessage, nodeSigner: NodeSigner, logger: Logger, customHandler: CustomOnionMessageHandler
	) -> Result_PeeledOnionNoneZ {
		// native call variable prep


		// native method call
		let nativeCallResult =
			withUnsafePointer(to: msg.cType!) { (msgPointer: UnsafePointer<LDKOnionMessage>) in
				peel_onion_message(
					msgPointer, nodeSigner.activate().cType!, logger.activate().cType!, customHandler.activate().cType!)
			}


		// cleanup


		// return value (do some wrapping)
		let returnValue = Result_PeeledOnionNoneZ(
			cType: nativeCallResult, instantiationContext: "Bindings.swift::\(#function):\(#line)")


		try! returnValue.addAnchor(anchor: msg)
		return returnValue
	}

	/// Pays the given [`Bolt11Invoice`], retrying if needed based on [`Retry`].
	///
	/// [`Bolt11Invoice::payment_hash`] is used as the [`PaymentId`], which ensures idempotency as long
	/// as the payment is still pending. If the payment succeeds, you must ensure that a second payment
	/// with the same [`PaymentHash`] is never sent.
	///
	/// If you wish to use a different payment idempotency token, see [`pay_invoice_with_id`].
	public class func payInvoice(invoice: Bolt11Invoice, retryStrategy: Retry, channelmanager: ChannelManager)
		-> Result_ThirtyTwoBytesPaymentErrorZ
	{
		// native call variable prep


		// native method call
		let nativeCallResult =
			withUnsafePointer(to: invoice.cType!) { (invoicePointer: UnsafePointer<LDKBolt11Invoice>) in

				withUnsafePointer(to: channelmanager.cType!) {
					(channelmanagerPointer: UnsafePointer<LDKChannelManager>) in
					pay_invoice(invoicePointer, retryStrategy.danglingClone().cType!, channelmanagerPointer)
				}

			}


		// cleanup


		// return value (do some wrapping)
		let returnValue = Result_ThirtyTwoBytesPaymentErrorZ(
			cType: nativeCallResult, instantiationContext: "Bindings.swift::\(#function):\(#line)")


		try! returnValue.addAnchor(anchor: invoice)
		try! returnValue.addAnchor(anchor: channelmanager)
		return returnValue
	}

	/// Pays the given [`Bolt11Invoice`] with a custom idempotency key, retrying if needed based on
	/// [`Retry`].
	///
	/// Note that idempotency is only guaranteed as long as the payment is still pending. Once the
	/// payment completes or fails, no idempotency guarantees are made.
	///
	/// You should ensure that the [`Bolt11Invoice::payment_hash`] is unique and the same
	/// [`PaymentHash`] has never been paid before.
	///
	/// See [`pay_invoice`] for a variant which uses the [`PaymentHash`] for the idempotency token.
	public class func payInvoiceWithId(
		invoice: Bolt11Invoice, paymentId: [UInt8], retryStrategy: Retry, channelmanager: ChannelManager
	) -> Result_NonePaymentErrorZ {
		// native call variable prep

		let paymentIdPrimitiveWrapper = ThirtyTwoBytes(
			value: paymentId, instantiationContext: "Bindings.swift::\(#function):\(#line)")


		// native method call
		let nativeCallResult =
			withUnsafePointer(to: invoice.cType!) { (invoicePointer: UnsafePointer<LDKBolt11Invoice>) in

				withUnsafePointer(to: channelmanager.cType!) {
					(channelmanagerPointer: UnsafePointer<LDKChannelManager>) in
					pay_invoice_with_id(
						invoicePointer, paymentIdPrimitiveWrapper.cType!, retryStrategy.danglingClone().cType!,
						channelmanagerPointer)
				}

			}


		// cleanup

		// for elided types, we need this
		paymentIdPrimitiveWrapper.noOpRetain()


		// return value (do some wrapping)
		let returnValue = Result_NonePaymentErrorZ(
			cType: nativeCallResult, instantiationContext: "Bindings.swift::\(#function):\(#line)")


		try! returnValue.addAnchor(anchor: invoice)
		try! returnValue.addAnchor(anchor: channelmanager)
		return returnValue
	}

	/// Pays the given zero-value [`Bolt11Invoice`] using the given amount, retrying if needed based on
	/// [`Retry`].
	///
	/// [`Bolt11Invoice::payment_hash`] is used as the [`PaymentId`], which ensures idempotency as long
	/// as the payment is still pending. If the payment succeeds, you must ensure that a second payment
	/// with the same [`PaymentHash`] is never sent.
	///
	/// If you wish to use a different payment idempotency token, see
	/// [`pay_zero_value_invoice_with_id`].
	public class func payZeroValueInvoice(
		invoice: Bolt11Invoice, amountMsats: UInt64, retryStrategy: Retry, channelmanager: ChannelManager
	) -> Result_ThirtyTwoBytesPaymentErrorZ {
		// native call variable prep


		// native method call
		let nativeCallResult =
			withUnsafePointer(to: invoice.cType!) { (invoicePointer: UnsafePointer<LDKBolt11Invoice>) in

				withUnsafePointer(to: channelmanager.cType!) {
					(channelmanagerPointer: UnsafePointer<LDKChannelManager>) in
					pay_zero_value_invoice(
						invoicePointer, amountMsats, retryStrategy.danglingClone().cType!, channelmanagerPointer)
				}

			}


		// cleanup


		// return value (do some wrapping)
		let returnValue = Result_ThirtyTwoBytesPaymentErrorZ(
			cType: nativeCallResult, instantiationContext: "Bindings.swift::\(#function):\(#line)")


		try! returnValue.addAnchor(anchor: invoice)
		try! returnValue.addAnchor(anchor: channelmanager)
		return returnValue
	}

	/// Pays the given zero-value [`Bolt11Invoice`] using the given amount and custom idempotency key,
	/// retrying if needed based on [`Retry`].
	///
	/// Note that idempotency is only guaranteed as long as the payment is still pending. Once the
	/// payment completes or fails, no idempotency guarantees are made.
	///
	/// You should ensure that the [`Bolt11Invoice::payment_hash`] is unique and the same
	/// [`PaymentHash`] has never been paid before.
	///
	/// See [`pay_zero_value_invoice`] for a variant which uses the [`PaymentHash`] for the
	/// idempotency token.
	public class func payZeroValueInvoiceWithId(
		invoice: Bolt11Invoice, amountMsats: UInt64, paymentId: [UInt8], retryStrategy: Retry,
		channelmanager: ChannelManager
	) -> Result_NonePaymentErrorZ {
		// native call variable prep

		let paymentIdPrimitiveWrapper = ThirtyTwoBytes(
			value: paymentId, instantiationContext: "Bindings.swift::\(#function):\(#line)")


		// native method call
		let nativeCallResult =
			withUnsafePointer(to: invoice.cType!) { (invoicePointer: UnsafePointer<LDKBolt11Invoice>) in

				withUnsafePointer(to: channelmanager.cType!) {
					(channelmanagerPointer: UnsafePointer<LDKChannelManager>) in
					pay_zero_value_invoice_with_id(
						invoicePointer, amountMsats, paymentIdPrimitiveWrapper.cType!,
						retryStrategy.danglingClone().cType!, channelmanagerPointer)
				}

			}


		// cleanup

		// for elided types, we need this
		paymentIdPrimitiveWrapper.noOpRetain()


		// return value (do some wrapping)
		let returnValue = Result_NonePaymentErrorZ(
			cType: nativeCallResult, instantiationContext: "Bindings.swift::\(#function):\(#line)")


		try! returnValue.addAnchor(anchor: invoice)
		try! returnValue.addAnchor(anchor: channelmanager)
		return returnValue
	}

	/// Sends payment probes over all paths of a route that would be used to pay the given invoice.
	///
	/// See [`ChannelManager::send_preflight_probes`] for more information.
	public class func preflightProbeInvoice(
		invoice: Bolt11Invoice, channelmanager: ChannelManager, liquidityLimitMultiplier: UInt64?
	) -> Result_CVec_C2Tuple_ThirtyTwoBytesThirtyTwoBytesZZProbingErrorZ {
		// native call variable prep

		let liquidityLimitMultiplierOption = Option_u64Z(
			some: liquidityLimitMultiplier, instantiationContext: "Bindings.swift::\(#function):\(#line)"
		)
		.danglingClone()


		// native method call
		let nativeCallResult =
			withUnsafePointer(to: invoice.cType!) { (invoicePointer: UnsafePointer<LDKBolt11Invoice>) in

				withUnsafePointer(to: channelmanager.cType!) {
					(channelmanagerPointer: UnsafePointer<LDKChannelManager>) in
					preflight_probe_invoice(
						invoicePointer, channelmanagerPointer, liquidityLimitMultiplierOption.cType!)
				}

			}


		// cleanup


		// return value (do some wrapping)
		let returnValue = Result_CVec_C2Tuple_ThirtyTwoBytesThirtyTwoBytesZZProbingErrorZ(
			cType: nativeCallResult, instantiationContext: "Bindings.swift::\(#function):\(#line)")


		try! returnValue.addAnchor(anchor: invoice)
		try! returnValue.addAnchor(anchor: channelmanager)
		return returnValue
	}

	/// Sends payment probes over all paths of a route that would be used to pay the given zero-value
	/// invoice using the given amount.
	///
	/// See [`ChannelManager::send_preflight_probes`] for more information.
	public class func preflightProbeZeroValueInvoice(
		invoice: Bolt11Invoice, amountMsat: UInt64, channelmanager: ChannelManager, liquidityLimitMultiplier: UInt64?
	) -> Result_CVec_C2Tuple_ThirtyTwoBytesThirtyTwoBytesZZProbingErrorZ {
		// native call variable prep

		let liquidityLimitMultiplierOption = Option_u64Z(
			some: liquidityLimitMultiplier, instantiationContext: "Bindings.swift::\(#function):\(#line)"
		)
		.danglingClone()


		// native method call
		let nativeCallResult =
			withUnsafePointer(to: invoice.cType!) { (invoicePointer: UnsafePointer<LDKBolt11Invoice>) in

				withUnsafePointer(to: channelmanager.cType!) {
					(channelmanagerPointer: UnsafePointer<LDKChannelManager>) in
					preflight_probe_zero_value_invoice(
						invoicePointer, amountMsat, channelmanagerPointer, liquidityLimitMultiplierOption.cType!)
				}

			}


		// cleanup


		// return value (do some wrapping)
		let returnValue = Result_CVec_C2Tuple_ThirtyTwoBytesThirtyTwoBytesZZProbingErrorZ(
			cType: nativeCallResult, instantiationContext: "Bindings.swift::\(#function):\(#line)")


		try! returnValue.addAnchor(anchor: invoice)
		try! returnValue.addAnchor(anchor: channelmanager)
		return returnValue
	}

	/// Utility to create an invoice that can be paid to one of multiple nodes, or a \"phantom invoice.\"
	/// See [`PhantomKeysManager`] for more information on phantom node payments.
	///
	/// `phantom_route_hints` parameter:
	/// * Contains channel info for all nodes participating in the phantom invoice
	/// * Entries are retrieved from a call to [`ChannelManager::get_phantom_route_hints`] on each
	/// participating node
	/// * It is fine to cache `phantom_route_hints` and reuse it across invoices, as long as the data is
	/// updated when a channel becomes disabled or closes
	/// * Note that if too many channels are included in [`PhantomRouteHints::channels`], the invoice
	/// may be too long for QR code scanning. To fix this, `PhantomRouteHints::channels` may be pared
	/// down
	///
	/// `payment_hash` can be specified if you have a specific need for a custom payment hash (see the difference
	/// between [`ChannelManager::create_inbound_payment`] and [`ChannelManager::create_inbound_payment_for_hash`]).
	/// If `None` is provided for `payment_hash`, then one will be created.
	///
	/// `invoice_expiry_delta_secs` describes the number of seconds that the invoice is valid for
	/// in excess of the current time.
	///
	/// `duration_since_epoch` is the current time since epoch in seconds.
	///
	/// You can specify a custom `min_final_cltv_expiry_delta`, or let LDK default it to
	/// [`MIN_FINAL_CLTV_EXPIRY_DELTA`]. The provided expiry must be at least [`MIN_FINAL_CLTV_EXPIRY_DELTA`] - 3.
	/// Note that LDK will add a buffer of 3 blocks to the delta to allow for up to a few new block
	/// confirmations during routing.
	///
	/// Note that the provided `keys_manager`'s `NodeSigner` implementation must support phantom
	/// invoices in its `sign_invoice` implementation ([`PhantomKeysManager`] satisfies this
	/// requirement).
	///
	/// [`PhantomKeysManager`]: lightning::sign::PhantomKeysManager
	/// [`ChannelManager::get_phantom_route_hints`]: lightning::ln::channelmanager::ChannelManager::get_phantom_route_hints
	/// [`ChannelManager::create_inbound_payment`]: lightning::ln::channelmanager::ChannelManager::create_inbound_payment
	/// [`ChannelManager::create_inbound_payment_for_hash`]: lightning::ln::channelmanager::ChannelManager::create_inbound_payment_for_hash
	/// [`PhantomRouteHints::channels`]: lightning::ln::channelmanager::PhantomRouteHints::channels
	/// [`MIN_FINAL_CLTV_EXPIRY_DETLA`]: lightning::ln::channelmanager::MIN_FINAL_CLTV_EXPIRY_DELTA
	///
	/// This can be used in a `no_std` environment, where [`std::time::SystemTime`] is not
	/// available and the current time is supplied by the caller.
	public class func createPhantomInvoice(
		amtMsat: UInt64?, paymentHash: [UInt8]?, description: String, invoiceExpiryDeltaSecs: UInt32,
		phantomRouteHints: [PhantomRouteHints], entropySource: EntropySource, nodeSigner: NodeSigner, logger: Logger,
		network: Currency, minFinalCltvExpiryDelta: UInt16?, durationSinceEpoch: UInt64
	) -> Result_Bolt11InvoiceSignOrCreationErrorZ {
		// native call variable prep

		let amtMsatOption = Option_u64Z(some: amtMsat, instantiationContext: "Bindings.swift::\(#function):\(#line)")
			.danglingClone()

		let paymentHashOption = Option_ThirtyTwoBytesZ(
			some: paymentHash, instantiationContext: "Bindings.swift::\(#function):\(#line)"
		)
		.danglingClone()

		let descriptionPrimitiveWrapper = Str(
			value: description, instantiationContext: "Bindings.swift::\(#function):\(#line)"
		)
		.dangle()

		let phantomRouteHintsVector = Vec_PhantomRouteHintsZ(
			array: phantomRouteHints, instantiationContext: "Bindings.swift::\(#function):\(#line)"
		)
		.dangle()

		let minFinalCltvExpiryDeltaOption = Option_u16Z(
			some: minFinalCltvExpiryDelta, instantiationContext: "Bindings.swift::\(#function):\(#line)"
		)
		.danglingClone()


		// native method call
		let nativeCallResult = create_phantom_invoice(
			amtMsatOption.cType!, paymentHashOption.cType!, descriptionPrimitiveWrapper.cType!, invoiceExpiryDeltaSecs,
			phantomRouteHintsVector.cType!, entropySource.activate().cType!, nodeSigner.activate().cType!,
			logger.activate().cType!, network.getCValue(), minFinalCltvExpiryDeltaOption.cType!, durationSinceEpoch)

		// cleanup

		// for elided types, we need this
		descriptionPrimitiveWrapper.noOpRetain()

		// phantomRouteHintsVector.noOpRetain()


		// return value (do some wrapping)
		let returnValue = Result_Bolt11InvoiceSignOrCreationErrorZ(
			cType: nativeCallResult, instantiationContext: "Bindings.swift::\(#function):\(#line)")


		return returnValue
	}

	/// Utility to create an invoice that can be paid to one of multiple nodes, or a \"phantom invoice.\"
	/// See [`PhantomKeysManager`] for more information on phantom node payments.
	///
	/// `phantom_route_hints` parameter:
	/// * Contains channel info for all nodes participating in the phantom invoice
	/// * Entries are retrieved from a call to [`ChannelManager::get_phantom_route_hints`] on each
	/// participating node
	/// * It is fine to cache `phantom_route_hints` and reuse it across invoices, as long as the data is
	/// updated when a channel becomes disabled or closes
	/// * Note that the route hints generated from `phantom_route_hints` will be limited to a maximum
	/// of 3 hints to ensure that the invoice can be scanned in a QR code. These hints are selected
	/// in the order that the nodes in `PhantomRouteHints` are specified, selecting one hint per node
	/// until the maximum is hit. Callers may provide as many `PhantomRouteHints::channels` as
	/// desired, but note that some nodes will be trimmed if more than 3 nodes are provided.
	///
	/// `description_hash` is a SHA-256 hash of the description text
	///
	/// `payment_hash` can be specified if you have a specific need for a custom payment hash (see the difference
	/// between [`ChannelManager::create_inbound_payment`] and [`ChannelManager::create_inbound_payment_for_hash`]).
	/// If `None` is provided for `payment_hash`, then one will be created.
	///
	/// `invoice_expiry_delta_secs` describes the number of seconds that the invoice is valid for
	/// in excess of the current time.
	///
	/// `duration_since_epoch` is the current time since epoch in seconds.
	///
	/// Note that the provided `keys_manager`'s `NodeSigner` implementation must support phantom
	/// invoices in its `sign_invoice` implementation ([`PhantomKeysManager`] satisfies this
	/// requirement).
	///
	/// [`PhantomKeysManager`]: lightning::sign::PhantomKeysManager
	/// [`ChannelManager::get_phantom_route_hints`]: lightning::ln::channelmanager::ChannelManager::get_phantom_route_hints
	/// [`ChannelManager::create_inbound_payment`]: lightning::ln::channelmanager::ChannelManager::create_inbound_payment
	/// [`ChannelManager::create_inbound_payment_for_hash`]: lightning::ln::channelmanager::ChannelManager::create_inbound_payment_for_hash
	/// [`PhantomRouteHints::channels`]: lightning::ln::channelmanager::PhantomRouteHints::channels
	///
	/// This can be used in a `no_std` environment, where [`std::time::SystemTime`] is not
	/// available and the current time is supplied by the caller.
	public class func createPhantomInvoiceWithDescriptionHash(
		amtMsat: UInt64?, paymentHash: [UInt8]?, invoiceExpiryDeltaSecs: UInt32, descriptionHash: Sha256,
		phantomRouteHints: [PhantomRouteHints], entropySource: EntropySource, nodeSigner: NodeSigner, logger: Logger,
		network: Currency, minFinalCltvExpiryDelta: UInt16?, durationSinceEpoch: UInt64
	) -> Result_Bolt11InvoiceSignOrCreationErrorZ {
		// native call variable prep

		let amtMsatOption = Option_u64Z(some: amtMsat, instantiationContext: "Bindings.swift::\(#function):\(#line)")
			.danglingClone()

		let paymentHashOption = Option_ThirtyTwoBytesZ(
			some: paymentHash, instantiationContext: "Bindings.swift::\(#function):\(#line)"
		)
		.danglingClone()

		let phantomRouteHintsVector = Vec_PhantomRouteHintsZ(
			array: phantomRouteHints, instantiationContext: "Bindings.swift::\(#function):\(#line)"
		)
		.dangle()

		let minFinalCltvExpiryDeltaOption = Option_u16Z(
			some: minFinalCltvExpiryDelta, instantiationContext: "Bindings.swift::\(#function):\(#line)"
		)
		.danglingClone()


		// native method call
		let nativeCallResult = create_phantom_invoice_with_description_hash(
			amtMsatOption.cType!, paymentHashOption.cType!, invoiceExpiryDeltaSecs,
			descriptionHash.dynamicallyDangledClone().cType!, phantomRouteHintsVector.cType!,
			entropySource.activate().cType!, nodeSigner.activate().cType!, logger.activate().cType!,
			network.getCValue(), minFinalCltvExpiryDeltaOption.cType!, durationSinceEpoch)

		// cleanup

		// phantomRouteHintsVector.noOpRetain()


		// return value (do some wrapping)
		let returnValue = Result_Bolt11InvoiceSignOrCreationErrorZ(
			cType: nativeCallResult, instantiationContext: "Bindings.swift::\(#function):\(#line)")


		return returnValue
	}

	/// Utility to construct an invoice. Generally, unless you want to do something like a custom
	/// cltv_expiry, this is what you should be using to create an invoice. The reason being, this
	/// method stores the invoice's payment secret and preimage in `ChannelManager`, so (a) the user
	/// doesn't have to store preimage/payment secret information and (b) `ChannelManager` can verify
	/// that the payment secret is valid when the invoice is paid.
	///
	/// `invoice_expiry_delta_secs` describes the number of seconds that the invoice is valid for
	/// in excess of the current time.
	///
	/// You can specify a custom `min_final_cltv_expiry_delta`, or let LDK default it to
	/// [`MIN_FINAL_CLTV_EXPIRY_DELTA`]. The provided expiry must be at least [`MIN_FINAL_CLTV_EXPIRY_DELTA`].
	/// Note that LDK will add a buffer of 3 blocks to the delta to allow for up to a few new block
	/// confirmations during routing.
	///
	/// [`MIN_FINAL_CLTV_EXPIRY_DETLA`]: lightning::ln::channelmanager::MIN_FINAL_CLTV_EXPIRY_DELTA
	public class func createInvoiceFromChannelmanager(
		channelmanager: ChannelManager, nodeSigner: NodeSigner, logger: Logger, network: Currency, amtMsat: UInt64?,
		description: String, invoiceExpiryDeltaSecs: UInt32, minFinalCltvExpiryDelta: UInt16?
	) -> Result_Bolt11InvoiceSignOrCreationErrorZ {
		// native call variable prep

		let amtMsatOption = Option_u64Z(some: amtMsat, instantiationContext: "Bindings.swift::\(#function):\(#line)")
			.danglingClone()

		let descriptionPrimitiveWrapper = Str(
			value: description, instantiationContext: "Bindings.swift::\(#function):\(#line)"
		)
		.dangle()

		let minFinalCltvExpiryDeltaOption = Option_u16Z(
			some: minFinalCltvExpiryDelta, instantiationContext: "Bindings.swift::\(#function):\(#line)"
		)
		.danglingClone()


		// native method call
		let nativeCallResult =
			withUnsafePointer(to: channelmanager.cType!) { (channelmanagerPointer: UnsafePointer<LDKChannelManager>) in
				create_invoice_from_channelmanager(
					channelmanagerPointer, nodeSigner.activate().cType!, logger.activate().cType!, network.getCValue(),
					amtMsatOption.cType!, descriptionPrimitiveWrapper.cType!, invoiceExpiryDeltaSecs,
					minFinalCltvExpiryDeltaOption.cType!)
			}


		// cleanup

		// for elided types, we need this
		descriptionPrimitiveWrapper.noOpRetain()


		// return value (do some wrapping)
		let returnValue = Result_Bolt11InvoiceSignOrCreationErrorZ(
			cType: nativeCallResult, instantiationContext: "Bindings.swift::\(#function):\(#line)")


		try! returnValue.addAnchor(anchor: channelmanager)
		return returnValue
	}

	/// Utility to construct an invoice. Generally, unless you want to do something like a custom
	/// cltv_expiry, this is what you should be using to create an invoice. The reason being, this
	/// method stores the invoice's payment secret and preimage in `ChannelManager`, so (a) the user
	/// doesn't have to store preimage/payment secret information and (b) `ChannelManager` can verify
	/// that the payment secret is valid when the invoice is paid.
	/// Use this variant if you want to pass the `description_hash` to the invoice.
	///
	/// `invoice_expiry_delta_secs` describes the number of seconds that the invoice is valid for
	/// in excess of the current time.
	///
	/// You can specify a custom `min_final_cltv_expiry_delta`, or let LDK default it to
	/// [`MIN_FINAL_CLTV_EXPIRY_DELTA`]. The provided expiry must be at least [`MIN_FINAL_CLTV_EXPIRY_DELTA`].
	/// Note that LDK will add a buffer of 3 blocks to the delta to allow for up to a few new block
	/// confirmations during routing.
	///
	/// [`MIN_FINAL_CLTV_EXPIRY_DETLA`]: lightning::ln::channelmanager::MIN_FINAL_CLTV_EXPIRY_DELTA
	public class func createInvoiceFromChannelmanagerWithDescriptionHash(
		channelmanager: ChannelManager, nodeSigner: NodeSigner, logger: Logger, network: Currency, amtMsat: UInt64?,
		descriptionHash: Sha256, invoiceExpiryDeltaSecs: UInt32, minFinalCltvExpiryDelta: UInt16?
	) -> Result_Bolt11InvoiceSignOrCreationErrorZ {
		// native call variable prep

		let amtMsatOption = Option_u64Z(some: amtMsat, instantiationContext: "Bindings.swift::\(#function):\(#line)")
			.danglingClone()

		let minFinalCltvExpiryDeltaOption = Option_u16Z(
			some: minFinalCltvExpiryDelta, instantiationContext: "Bindings.swift::\(#function):\(#line)"
		)
		.danglingClone()


		// native method call
		let nativeCallResult =
			withUnsafePointer(to: channelmanager.cType!) { (channelmanagerPointer: UnsafePointer<LDKChannelManager>) in
				create_invoice_from_channelmanager_with_description_hash(
					channelmanagerPointer, nodeSigner.activate().cType!, logger.activate().cType!, network.getCValue(),
					amtMsatOption.cType!, descriptionHash.dynamicallyDangledClone().cType!, invoiceExpiryDeltaSecs,
					minFinalCltvExpiryDeltaOption.cType!)
			}


		// cleanup


		// return value (do some wrapping)
		let returnValue = Result_Bolt11InvoiceSignOrCreationErrorZ(
			cType: nativeCallResult, instantiationContext: "Bindings.swift::\(#function):\(#line)")


		try! returnValue.addAnchor(anchor: channelmanager)
		return returnValue
	}

	/// See [`create_invoice_from_channelmanager_with_description_hash`]
	/// This version can be used in a `no_std` environment, where [`std::time::SystemTime`] is not
	/// available and the current time is supplied by the caller.
	public class func createInvoiceFromChannelmanagerWithDescriptionHashAndDurationSinceEpoch(
		channelmanager: ChannelManager, nodeSigner: NodeSigner, logger: Logger, network: Currency, amtMsat: UInt64?,
		descriptionHash: Sha256, durationSinceEpoch: UInt64, invoiceExpiryDeltaSecs: UInt32,
		minFinalCltvExpiryDelta: UInt16?
	) -> Result_Bolt11InvoiceSignOrCreationErrorZ {
		// native call variable prep

		let amtMsatOption = Option_u64Z(some: amtMsat, instantiationContext: "Bindings.swift::\(#function):\(#line)")
			.danglingClone()

		let minFinalCltvExpiryDeltaOption = Option_u16Z(
			some: minFinalCltvExpiryDelta, instantiationContext: "Bindings.swift::\(#function):\(#line)"
		)
		.danglingClone()


		// native method call
		let nativeCallResult =
			withUnsafePointer(to: channelmanager.cType!) { (channelmanagerPointer: UnsafePointer<LDKChannelManager>) in
				create_invoice_from_channelmanager_with_description_hash_and_duration_since_epoch(
					channelmanagerPointer, nodeSigner.activate().cType!, logger.activate().cType!, network.getCValue(),
					amtMsatOption.cType!, descriptionHash.dynamicallyDangledClone().cType!, durationSinceEpoch,
					invoiceExpiryDeltaSecs, minFinalCltvExpiryDeltaOption.cType!)
			}


		// cleanup


		// return value (do some wrapping)
		let returnValue = Result_Bolt11InvoiceSignOrCreationErrorZ(
			cType: nativeCallResult, instantiationContext: "Bindings.swift::\(#function):\(#line)")


		try! returnValue.addAnchor(anchor: channelmanager)
		return returnValue
	}

	/// See [`create_invoice_from_channelmanager`]
	/// This version can be used in a `no_std` environment, where [`std::time::SystemTime`] is not
	/// available and the current time is supplied by the caller.
	public class func createInvoiceFromChannelmanagerAndDurationSinceEpoch(
		channelmanager: ChannelManager, nodeSigner: NodeSigner, logger: Logger, network: Currency, amtMsat: UInt64?,
		description: String, durationSinceEpoch: UInt64, invoiceExpiryDeltaSecs: UInt32,
		minFinalCltvExpiryDelta: UInt16?
	) -> Result_Bolt11InvoiceSignOrCreationErrorZ {
		// native call variable prep

		let amtMsatOption = Option_u64Z(some: amtMsat, instantiationContext: "Bindings.swift::\(#function):\(#line)")
			.danglingClone()

		let descriptionPrimitiveWrapper = Str(
			value: description, instantiationContext: "Bindings.swift::\(#function):\(#line)"
		)
		.dangle()

		let minFinalCltvExpiryDeltaOption = Option_u16Z(
			some: minFinalCltvExpiryDelta, instantiationContext: "Bindings.swift::\(#function):\(#line)"
		)
		.danglingClone()


		// native method call
		let nativeCallResult =
			withUnsafePointer(to: channelmanager.cType!) { (channelmanagerPointer: UnsafePointer<LDKChannelManager>) in
				create_invoice_from_channelmanager_and_duration_since_epoch(
					channelmanagerPointer, nodeSigner.activate().cType!, logger.activate().cType!, network.getCValue(),
					amtMsatOption.cType!, descriptionPrimitiveWrapper.cType!, durationSinceEpoch,
					invoiceExpiryDeltaSecs, minFinalCltvExpiryDeltaOption.cType!)
			}


		// cleanup

		// for elided types, we need this
		descriptionPrimitiveWrapper.noOpRetain()


		// return value (do some wrapping)
		let returnValue = Result_Bolt11InvoiceSignOrCreationErrorZ(
			cType: nativeCallResult, instantiationContext: "Bindings.swift::\(#function):\(#line)")


		try! returnValue.addAnchor(anchor: channelmanager)
		return returnValue
	}

	/// See [`create_invoice_from_channelmanager_and_duration_since_epoch`]
	/// This version allows for providing a custom [`PaymentHash`] for the invoice.
	/// This may be useful if you're building an on-chain swap or involving another protocol where
	/// the payment hash is also involved outside the scope of lightning.
	public class func createInvoiceFromChannelmanagerAndDurationSinceEpochWithPaymentHash(
		channelmanager: ChannelManager, nodeSigner: NodeSigner, logger: Logger, network: Currency, amtMsat: UInt64?,
		description: String, durationSinceEpoch: UInt64, invoiceExpiryDeltaSecs: UInt32, paymentHash: [UInt8],
		minFinalCltvExpiryDelta: UInt16?
	) -> Result_Bolt11InvoiceSignOrCreationErrorZ {
		// native call variable prep

		let amtMsatOption = Option_u64Z(some: amtMsat, instantiationContext: "Bindings.swift::\(#function):\(#line)")
			.danglingClone()

		let descriptionPrimitiveWrapper = Str(
			value: description, instantiationContext: "Bindings.swift::\(#function):\(#line)"
		)
		.dangle()

		let paymentHashPrimitiveWrapper = ThirtyTwoBytes(
			value: paymentHash, instantiationContext: "Bindings.swift::\(#function):\(#line)")

		let minFinalCltvExpiryDeltaOption = Option_u16Z(
			some: minFinalCltvExpiryDelta, instantiationContext: "Bindings.swift::\(#function):\(#line)"
		)
		.danglingClone()


		// native method call
		let nativeCallResult =
			withUnsafePointer(to: channelmanager.cType!) { (channelmanagerPointer: UnsafePointer<LDKChannelManager>) in
				create_invoice_from_channelmanager_and_duration_since_epoch_with_payment_hash(
					channelmanagerPointer, nodeSigner.activate().cType!, logger.activate().cType!, network.getCValue(),
					amtMsatOption.cType!, descriptionPrimitiveWrapper.cType!, durationSinceEpoch,
					invoiceExpiryDeltaSecs, paymentHashPrimitiveWrapper.cType!, minFinalCltvExpiryDeltaOption.cType!)
			}


		// cleanup

		// for elided types, we need this
		descriptionPrimitiveWrapper.noOpRetain()

		// for elided types, we need this
		paymentHashPrimitiveWrapper.noOpRetain()


		// return value (do some wrapping)
		let returnValue = Result_Bolt11InvoiceSignOrCreationErrorZ(
			cType: nativeCallResult, instantiationContext: "Bindings.swift::\(#function):\(#line)")


		try! returnValue.addAnchor(anchor: channelmanager)
		return returnValue
	}

	/// Read a C2Tuple_ThirtyTwoBytesChannelManagerZ from a byte array, created by C2Tuple_ThirtyTwoBytesChannelManagerZ_write
	@available(
		*, deprecated, message: "This method passes the following non-cloneable, but freeable objects by value: `arg`."
	)
	public class func readThirtyTwoBytesChannelManager(ser: [UInt8], arg: ChannelManagerReadArgs)
		-> Result_C2Tuple_ThirtyTwoBytesChannelManagerZDecodeErrorZ
	{
		// native call variable prep

		let serPrimitiveWrapper = u8slice(value: ser, instantiationContext: "Bindings.swift::\(#function):\(#line)")


		// native method call
		let nativeCallResult = C2Tuple_ThirtyTwoBytesChannelManagerZ_read(
			serPrimitiveWrapper.cType!, arg.dangle().cType!)

		// cleanup

		// for elided types, we need this
		serPrimitiveWrapper.noOpRetain()


		// return value (do some wrapping)
		let returnValue = Result_C2Tuple_ThirtyTwoBytesChannelManagerZDecodeErrorZ(
			cType: nativeCallResult, instantiationContext: "Bindings.swift::\(#function):\(#line)")


		return returnValue
	}

	/// Read a C2Tuple_ThirtyTwoBytesChannelMonitorZ from a byte array, created by C2Tuple_ThirtyTwoBytesChannelMonitorZ_write
	public class func readThirtyTwoBytesChannelMonitor(ser: [UInt8], argA: EntropySource, argB: SignerProvider)
		-> Result_C2Tuple_ThirtyTwoBytesChannelMonitorZDecodeErrorZ
	{
		// native call variable prep

		let serPrimitiveWrapper = u8slice(value: ser, instantiationContext: "Bindings.swift::\(#function):\(#line)")


		// native method call
		let nativeCallResult =
			withUnsafePointer(to: argA.activate().cType!) { (argAPointer: UnsafePointer<LDKEntropySource>) in

				withUnsafePointer(to: argB.activate().cType!) { (argBPointer: UnsafePointer<LDKSignerProvider>) in
					C2Tuple_ThirtyTwoBytesChannelMonitorZ_read(serPrimitiveWrapper.cType!, argAPointer, argBPointer)
				}

			}


		// cleanup

		// for elided types, we need this
		serPrimitiveWrapper.noOpRetain()


		// return value (do some wrapping)
		let returnValue = Result_C2Tuple_ThirtyTwoBytesChannelMonitorZDecodeErrorZ(
			cType: nativeCallResult, instantiationContext: "Bindings.swift::\(#function):\(#line)")


		return returnValue
	}


	internal typealias UInt8Tuple16 = (
		UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8
	)

	internal typealias UInt8Tuple32 = (
		UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
		UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8
	)

	internal typealias UInt8Tuple20 = (
		UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
		UInt8, UInt8, UInt8, UInt8
	)

	internal typealias UInt8Tuple33 = (
		UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
		UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
		UInt8
	)

	internal typealias UInt8Tuple64 = (
		UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
		UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
		UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
		UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8
	)

	internal typealias UInt8Tuple68 = (
		UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
		UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
		UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
		UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
		UInt8, UInt8, UInt8, UInt8
	)

	internal typealias UInt8Tuple4 = (UInt8, UInt8, UInt8, UInt8)

	internal typealias UInt8Tuple12 = (
		UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8
	)

	internal typealias UInt8Tuple3 = (UInt8, UInt8, UInt8)

	internal typealias UInt8Tuple80 = (
		UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
		UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
		UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
		UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
		UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8
	)

	internal typealias UInt16Tuple32 = (
		UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16,
		UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16,
		UInt16, UInt16, UInt16, UInt16
	)


	internal class func arrayToUInt8Tuple16(array: [UInt8]) -> UInt8Tuple16 {
		return (
			array[0], array[1], array[2], array[3], array[4], array[5], array[6], array[7], array[8], array[9],
			array[10], array[11], array[12], array[13], array[14], array[15]
		)
	}

	internal class func UInt8Tuple16ToArray(tuple: UInt8Tuple16) -> [UInt8] {
		return [
			tuple.0, tuple.1, tuple.2, tuple.3, tuple.4, tuple.5, tuple.6, tuple.7, tuple.8, tuple.9, tuple.10,
			tuple.11, tuple.12, tuple.13, tuple.14, tuple.15,
		]
	}

	internal class func arrayToUInt8Tuple32(array: [UInt8]) -> UInt8Tuple32 {
		return (
			array[0], array[1], array[2], array[3], array[4], array[5], array[6], array[7], array[8], array[9],
			array[10], array[11], array[12], array[13], array[14], array[15], array[16], array[17], array[18],
			array[19], array[20], array[21], array[22], array[23], array[24], array[25], array[26], array[27],
			array[28], array[29], array[30], array[31]
		)
	}

	internal class func UInt8Tuple32ToArray(tuple: UInt8Tuple32) -> [UInt8] {
		return [
			tuple.0, tuple.1, tuple.2, tuple.3, tuple.4, tuple.5, tuple.6, tuple.7, tuple.8, tuple.9, tuple.10,
			tuple.11, tuple.12, tuple.13, tuple.14, tuple.15, tuple.16, tuple.17, tuple.18, tuple.19, tuple.20,
			tuple.21, tuple.22, tuple.23, tuple.24, tuple.25, tuple.26, tuple.27, tuple.28, tuple.29, tuple.30,
			tuple.31,
		]
	}

	internal class func arrayToUInt8Tuple20(array: [UInt8]) -> UInt8Tuple20 {
		return (
			array[0], array[1], array[2], array[3], array[4], array[5], array[6], array[7], array[8], array[9],
			array[10], array[11], array[12], array[13], array[14], array[15], array[16], array[17], array[18], array[19]
		)
	}

	internal class func UInt8Tuple20ToArray(tuple: UInt8Tuple20) -> [UInt8] {
		return [
			tuple.0, tuple.1, tuple.2, tuple.3, tuple.4, tuple.5, tuple.6, tuple.7, tuple.8, tuple.9, tuple.10,
			tuple.11, tuple.12, tuple.13, tuple.14, tuple.15, tuple.16, tuple.17, tuple.18, tuple.19,
		]
	}

	internal class func arrayToUInt8Tuple33(array: [UInt8]) -> UInt8Tuple33 {
		return (
			array[0], array[1], array[2], array[3], array[4], array[5], array[6], array[7], array[8], array[9],
			array[10], array[11], array[12], array[13], array[14], array[15], array[16], array[17], array[18],
			array[19], array[20], array[21], array[22], array[23], array[24], array[25], array[26], array[27],
			array[28], array[29], array[30], array[31], array[32]
		)
	}

	internal class func UInt8Tuple33ToArray(tuple: UInt8Tuple33) -> [UInt8] {
		return [
			tuple.0, tuple.1, tuple.2, tuple.3, tuple.4, tuple.5, tuple.6, tuple.7, tuple.8, tuple.9, tuple.10,
			tuple.11, tuple.12, tuple.13, tuple.14, tuple.15, tuple.16, tuple.17, tuple.18, tuple.19, tuple.20,
			tuple.21, tuple.22, tuple.23, tuple.24, tuple.25, tuple.26, tuple.27, tuple.28, tuple.29, tuple.30,
			tuple.31, tuple.32,
		]
	}

	internal class func arrayToUInt8Tuple64(array: [UInt8]) -> UInt8Tuple64 {
		return (
			array[0], array[1], array[2], array[3], array[4], array[5], array[6], array[7], array[8], array[9],
			array[10], array[11], array[12], array[13], array[14], array[15], array[16], array[17], array[18],
			array[19], array[20], array[21], array[22], array[23], array[24], array[25], array[26], array[27],
			array[28], array[29], array[30], array[31], array[32], array[33], array[34], array[35], array[36],
			array[37], array[38], array[39], array[40], array[41], array[42], array[43], array[44], array[45],
			array[46], array[47], array[48], array[49], array[50], array[51], array[52], array[53], array[54],
			array[55], array[56], array[57], array[58], array[59], array[60], array[61], array[62], array[63]
		)
	}

	internal class func UInt8Tuple64ToArray(tuple: UInt8Tuple64) -> [UInt8] {
		return [
			tuple.0, tuple.1, tuple.2, tuple.3, tuple.4, tuple.5, tuple.6, tuple.7, tuple.8, tuple.9, tuple.10,
			tuple.11, tuple.12, tuple.13, tuple.14, tuple.15, tuple.16, tuple.17, tuple.18, tuple.19, tuple.20,
			tuple.21, tuple.22, tuple.23, tuple.24, tuple.25, tuple.26, tuple.27, tuple.28, tuple.29, tuple.30,
			tuple.31, tuple.32, tuple.33, tuple.34, tuple.35, tuple.36, tuple.37, tuple.38, tuple.39, tuple.40,
			tuple.41, tuple.42, tuple.43, tuple.44, tuple.45, tuple.46, tuple.47, tuple.48, tuple.49, tuple.50,
			tuple.51, tuple.52, tuple.53, tuple.54, tuple.55, tuple.56, tuple.57, tuple.58, tuple.59, tuple.60,
			tuple.61, tuple.62, tuple.63,
		]
	}

	internal class func arrayToUInt8Tuple68(array: [UInt8]) -> UInt8Tuple68 {
		return (
			array[0], array[1], array[2], array[3], array[4], array[5], array[6], array[7], array[8], array[9],
			array[10], array[11], array[12], array[13], array[14], array[15], array[16], array[17], array[18],
			array[19], array[20], array[21], array[22], array[23], array[24], array[25], array[26], array[27],
			array[28], array[29], array[30], array[31], array[32], array[33], array[34], array[35], array[36],
			array[37], array[38], array[39], array[40], array[41], array[42], array[43], array[44], array[45],
			array[46], array[47], array[48], array[49], array[50], array[51], array[52], array[53], array[54],
			array[55], array[56], array[57], array[58], array[59], array[60], array[61], array[62], array[63],
			array[64], array[65], array[66], array[67]
		)
	}

	internal class func UInt8Tuple68ToArray(tuple: UInt8Tuple68) -> [UInt8] {
		return [
			tuple.0, tuple.1, tuple.2, tuple.3, tuple.4, tuple.5, tuple.6, tuple.7, tuple.8, tuple.9, tuple.10,
			tuple.11, tuple.12, tuple.13, tuple.14, tuple.15, tuple.16, tuple.17, tuple.18, tuple.19, tuple.20,
			tuple.21, tuple.22, tuple.23, tuple.24, tuple.25, tuple.26, tuple.27, tuple.28, tuple.29, tuple.30,
			tuple.31, tuple.32, tuple.33, tuple.34, tuple.35, tuple.36, tuple.37, tuple.38, tuple.39, tuple.40,
			tuple.41, tuple.42, tuple.43, tuple.44, tuple.45, tuple.46, tuple.47, tuple.48, tuple.49, tuple.50,
			tuple.51, tuple.52, tuple.53, tuple.54, tuple.55, tuple.56, tuple.57, tuple.58, tuple.59, tuple.60,
			tuple.61, tuple.62, tuple.63, tuple.64, tuple.65, tuple.66, tuple.67,
		]
	}

	internal class func arrayToUInt8Tuple4(array: [UInt8]) -> UInt8Tuple4 {
		return (array[0], array[1], array[2], array[3])
	}

	internal class func UInt8Tuple4ToArray(tuple: UInt8Tuple4) -> [UInt8] {
		return [tuple.0, tuple.1, tuple.2, tuple.3]
	}

	internal class func arrayToUInt8Tuple12(array: [UInt8]) -> UInt8Tuple12 {
		return (
			array[0], array[1], array[2], array[3], array[4], array[5], array[6], array[7], array[8], array[9],
			array[10], array[11]
		)
	}

	internal class func UInt8Tuple12ToArray(tuple: UInt8Tuple12) -> [UInt8] {
		return [
			tuple.0, tuple.1, tuple.2, tuple.3, tuple.4, tuple.5, tuple.6, tuple.7, tuple.8, tuple.9, tuple.10,
			tuple.11,
		]
	}

	internal class func arrayToUInt8Tuple3(array: [UInt8]) -> UInt8Tuple3 {
		return (array[0], array[1], array[2])
	}

	internal class func UInt8Tuple3ToArray(tuple: UInt8Tuple3) -> [UInt8] {
		return [tuple.0, tuple.1, tuple.2]
	}

	internal class func arrayToUInt8Tuple80(array: [UInt8]) -> UInt8Tuple80 {
		return (
			array[0], array[1], array[2], array[3], array[4], array[5], array[6], array[7], array[8], array[9],
			array[10], array[11], array[12], array[13], array[14], array[15], array[16], array[17], array[18],
			array[19], array[20], array[21], array[22], array[23], array[24], array[25], array[26], array[27],
			array[28], array[29], array[30], array[31], array[32], array[33], array[34], array[35], array[36],
			array[37], array[38], array[39], array[40], array[41], array[42], array[43], array[44], array[45],
			array[46], array[47], array[48], array[49], array[50], array[51], array[52], array[53], array[54],
			array[55], array[56], array[57], array[58], array[59], array[60], array[61], array[62], array[63],
			array[64], array[65], array[66], array[67], array[68], array[69], array[70], array[71], array[72],
			array[73], array[74], array[75], array[76], array[77], array[78], array[79]
		)
	}

	internal class func UInt8Tuple80ToArray(tuple: UInt8Tuple80) -> [UInt8] {
		return [
			tuple.0, tuple.1, tuple.2, tuple.3, tuple.4, tuple.5, tuple.6, tuple.7, tuple.8, tuple.9, tuple.10,
			tuple.11, tuple.12, tuple.13, tuple.14, tuple.15, tuple.16, tuple.17, tuple.18, tuple.19, tuple.20,
			tuple.21, tuple.22, tuple.23, tuple.24, tuple.25, tuple.26, tuple.27, tuple.28, tuple.29, tuple.30,
			tuple.31, tuple.32, tuple.33, tuple.34, tuple.35, tuple.36, tuple.37, tuple.38, tuple.39, tuple.40,
			tuple.41, tuple.42, tuple.43, tuple.44, tuple.45, tuple.46, tuple.47, tuple.48, tuple.49, tuple.50,
			tuple.51, tuple.52, tuple.53, tuple.54, tuple.55, tuple.56, tuple.57, tuple.58, tuple.59, tuple.60,
			tuple.61, tuple.62, tuple.63, tuple.64, tuple.65, tuple.66, tuple.67, tuple.68, tuple.69, tuple.70,
			tuple.71, tuple.72, tuple.73, tuple.74, tuple.75, tuple.76, tuple.77, tuple.78, tuple.79,
		]
	}

	internal class func arrayToUInt16Tuple32(array: [UInt16]) -> UInt16Tuple32 {
		return (
			array[0], array[1], array[2], array[3], array[4], array[5], array[6], array[7], array[8], array[9],
			array[10], array[11], array[12], array[13], array[14], array[15], array[16], array[17], array[18],
			array[19], array[20], array[21], array[22], array[23], array[24], array[25], array[26], array[27],
			array[28], array[29], array[30], array[31]
		)
	}

	internal class func UInt16Tuple32ToArray(tuple: UInt16Tuple32) -> [UInt16] {
		return [
			tuple.0, tuple.1, tuple.2, tuple.3, tuple.4, tuple.5, tuple.6, tuple.7, tuple.8, tuple.9, tuple.10,
			tuple.11, tuple.12, tuple.13, tuple.14, tuple.15, tuple.16, tuple.17, tuple.18, tuple.19, tuple.20,
			tuple.21, tuple.22, tuple.23, tuple.24, tuple.25, tuple.26, tuple.27, tuple.28, tuple.29, tuple.30,
			tuple.31,
		]
	}


}

public class InstanceCrashSimulator: NativeTraitWrapper {

	public init() {
		super.init(conflictAvoidingVariableName: 0, instantiationContext: "Bindings.swift::\(#function):\(#line)")
	}

	public func getPointer() -> UnsafeMutableRawPointer {
		let pointer = Bindings.instanceToPointer(instance: self)
		return pointer
	}

}


func == (tupleA: Bindings.UInt8Tuple16, tupleB: Bindings.UInt8Tuple16) -> Bool {
	return tupleA.0 == tupleB.0 && tupleA.1 == tupleB.1 && tupleA.2 == tupleB.2 && tupleA.3 == tupleB.3
		&& tupleA.4 == tupleB.4 && tupleA.5 == tupleB.5 && tupleA.6 == tupleB.6 && tupleA.7 == tupleB.7
		&& tupleA.8 == tupleB.8 && tupleA.9 == tupleB.9 && tupleA.10 == tupleB.10 && tupleA.11 == tupleB.11
		&& tupleA.12 == tupleB.12 && tupleA.13 == tupleB.13 && tupleA.14 == tupleB.14 && tupleA.15 == tupleB.15
}

func == (tupleA: Bindings.UInt8Tuple32, tupleB: Bindings.UInt8Tuple32) -> Bool {
	return tupleA.0 == tupleB.0 && tupleA.1 == tupleB.1 && tupleA.2 == tupleB.2 && tupleA.3 == tupleB.3
		&& tupleA.4 == tupleB.4 && tupleA.5 == tupleB.5 && tupleA.6 == tupleB.6 && tupleA.7 == tupleB.7
		&& tupleA.8 == tupleB.8 && tupleA.9 == tupleB.9 && tupleA.10 == tupleB.10 && tupleA.11 == tupleB.11
		&& tupleA.12 == tupleB.12 && tupleA.13 == tupleB.13 && tupleA.14 == tupleB.14 && tupleA.15 == tupleB.15
		&& tupleA.16 == tupleB.16 && tupleA.17 == tupleB.17 && tupleA.18 == tupleB.18 && tupleA.19 == tupleB.19
		&& tupleA.20 == tupleB.20 && tupleA.21 == tupleB.21 && tupleA.22 == tupleB.22 && tupleA.23 == tupleB.23
		&& tupleA.24 == tupleB.24 && tupleA.25 == tupleB.25 && tupleA.26 == tupleB.26 && tupleA.27 == tupleB.27
		&& tupleA.28 == tupleB.28 && tupleA.29 == tupleB.29 && tupleA.30 == tupleB.30 && tupleA.31 == tupleB.31
}

func == (tupleA: Bindings.UInt8Tuple20, tupleB: Bindings.UInt8Tuple20) -> Bool {
	return tupleA.0 == tupleB.0 && tupleA.1 == tupleB.1 && tupleA.2 == tupleB.2 && tupleA.3 == tupleB.3
		&& tupleA.4 == tupleB.4 && tupleA.5 == tupleB.5 && tupleA.6 == tupleB.6 && tupleA.7 == tupleB.7
		&& tupleA.8 == tupleB.8 && tupleA.9 == tupleB.9 && tupleA.10 == tupleB.10 && tupleA.11 == tupleB.11
		&& tupleA.12 == tupleB.12 && tupleA.13 == tupleB.13 && tupleA.14 == tupleB.14 && tupleA.15 == tupleB.15
		&& tupleA.16 == tupleB.16 && tupleA.17 == tupleB.17 && tupleA.18 == tupleB.18 && tupleA.19 == tupleB.19
}

func == (tupleA: Bindings.UInt8Tuple33, tupleB: Bindings.UInt8Tuple33) -> Bool {
	return tupleA.0 == tupleB.0 && tupleA.1 == tupleB.1 && tupleA.2 == tupleB.2 && tupleA.3 == tupleB.3
		&& tupleA.4 == tupleB.4 && tupleA.5 == tupleB.5 && tupleA.6 == tupleB.6 && tupleA.7 == tupleB.7
		&& tupleA.8 == tupleB.8 && tupleA.9 == tupleB.9 && tupleA.10 == tupleB.10 && tupleA.11 == tupleB.11
		&& tupleA.12 == tupleB.12 && tupleA.13 == tupleB.13 && tupleA.14 == tupleB.14 && tupleA.15 == tupleB.15
		&& tupleA.16 == tupleB.16 && tupleA.17 == tupleB.17 && tupleA.18 == tupleB.18 && tupleA.19 == tupleB.19
		&& tupleA.20 == tupleB.20 && tupleA.21 == tupleB.21 && tupleA.22 == tupleB.22 && tupleA.23 == tupleB.23
		&& tupleA.24 == tupleB.24 && tupleA.25 == tupleB.25 && tupleA.26 == tupleB.26 && tupleA.27 == tupleB.27
		&& tupleA.28 == tupleB.28 && tupleA.29 == tupleB.29 && tupleA.30 == tupleB.30 && tupleA.31 == tupleB.31
		&& tupleA.32 == tupleB.32
}

func == (tupleA: Bindings.UInt8Tuple64, tupleB: Bindings.UInt8Tuple64) -> Bool {
	return tupleA.0 == tupleB.0 && tupleA.1 == tupleB.1 && tupleA.2 == tupleB.2 && tupleA.3 == tupleB.3
		&& tupleA.4 == tupleB.4 && tupleA.5 == tupleB.5 && tupleA.6 == tupleB.6 && tupleA.7 == tupleB.7
		&& tupleA.8 == tupleB.8 && tupleA.9 == tupleB.9 && tupleA.10 == tupleB.10 && tupleA.11 == tupleB.11
		&& tupleA.12 == tupleB.12 && tupleA.13 == tupleB.13 && tupleA.14 == tupleB.14 && tupleA.15 == tupleB.15
		&& tupleA.16 == tupleB.16 && tupleA.17 == tupleB.17 && tupleA.18 == tupleB.18 && tupleA.19 == tupleB.19
		&& tupleA.20 == tupleB.20 && tupleA.21 == tupleB.21 && tupleA.22 == tupleB.22 && tupleA.23 == tupleB.23
		&& tupleA.24 == tupleB.24 && tupleA.25 == tupleB.25 && tupleA.26 == tupleB.26 && tupleA.27 == tupleB.27
		&& tupleA.28 == tupleB.28 && tupleA.29 == tupleB.29 && tupleA.30 == tupleB.30 && tupleA.31 == tupleB.31
		&& tupleA.32 == tupleB.32 && tupleA.33 == tupleB.33 && tupleA.34 == tupleB.34 && tupleA.35 == tupleB.35
		&& tupleA.36 == tupleB.36 && tupleA.37 == tupleB.37 && tupleA.38 == tupleB.38 && tupleA.39 == tupleB.39
		&& tupleA.40 == tupleB.40 && tupleA.41 == tupleB.41 && tupleA.42 == tupleB.42 && tupleA.43 == tupleB.43
		&& tupleA.44 == tupleB.44 && tupleA.45 == tupleB.45 && tupleA.46 == tupleB.46 && tupleA.47 == tupleB.47
		&& tupleA.48 == tupleB.48 && tupleA.49 == tupleB.49 && tupleA.50 == tupleB.50 && tupleA.51 == tupleB.51
		&& tupleA.52 == tupleB.52 && tupleA.53 == tupleB.53 && tupleA.54 == tupleB.54 && tupleA.55 == tupleB.55
		&& tupleA.56 == tupleB.56 && tupleA.57 == tupleB.57 && tupleA.58 == tupleB.58 && tupleA.59 == tupleB.59
		&& tupleA.60 == tupleB.60 && tupleA.61 == tupleB.61 && tupleA.62 == tupleB.62 && tupleA.63 == tupleB.63
}

func == (tupleA: Bindings.UInt8Tuple68, tupleB: Bindings.UInt8Tuple68) -> Bool {
	return tupleA.0 == tupleB.0 && tupleA.1 == tupleB.1 && tupleA.2 == tupleB.2 && tupleA.3 == tupleB.3
		&& tupleA.4 == tupleB.4 && tupleA.5 == tupleB.5 && tupleA.6 == tupleB.6 && tupleA.7 == tupleB.7
		&& tupleA.8 == tupleB.8 && tupleA.9 == tupleB.9 && tupleA.10 == tupleB.10 && tupleA.11 == tupleB.11
		&& tupleA.12 == tupleB.12 && tupleA.13 == tupleB.13 && tupleA.14 == tupleB.14 && tupleA.15 == tupleB.15
		&& tupleA.16 == tupleB.16 && tupleA.17 == tupleB.17 && tupleA.18 == tupleB.18 && tupleA.19 == tupleB.19
		&& tupleA.20 == tupleB.20 && tupleA.21 == tupleB.21 && tupleA.22 == tupleB.22 && tupleA.23 == tupleB.23
		&& tupleA.24 == tupleB.24 && tupleA.25 == tupleB.25 && tupleA.26 == tupleB.26 && tupleA.27 == tupleB.27
		&& tupleA.28 == tupleB.28 && tupleA.29 == tupleB.29 && tupleA.30 == tupleB.30 && tupleA.31 == tupleB.31
		&& tupleA.32 == tupleB.32 && tupleA.33 == tupleB.33 && tupleA.34 == tupleB.34 && tupleA.35 == tupleB.35
		&& tupleA.36 == tupleB.36 && tupleA.37 == tupleB.37 && tupleA.38 == tupleB.38 && tupleA.39 == tupleB.39
		&& tupleA.40 == tupleB.40 && tupleA.41 == tupleB.41 && tupleA.42 == tupleB.42 && tupleA.43 == tupleB.43
		&& tupleA.44 == tupleB.44 && tupleA.45 == tupleB.45 && tupleA.46 == tupleB.46 && tupleA.47 == tupleB.47
		&& tupleA.48 == tupleB.48 && tupleA.49 == tupleB.49 && tupleA.50 == tupleB.50 && tupleA.51 == tupleB.51
		&& tupleA.52 == tupleB.52 && tupleA.53 == tupleB.53 && tupleA.54 == tupleB.54 && tupleA.55 == tupleB.55
		&& tupleA.56 == tupleB.56 && tupleA.57 == tupleB.57 && tupleA.58 == tupleB.58 && tupleA.59 == tupleB.59
		&& tupleA.60 == tupleB.60 && tupleA.61 == tupleB.61 && tupleA.62 == tupleB.62 && tupleA.63 == tupleB.63
		&& tupleA.64 == tupleB.64 && tupleA.65 == tupleB.65 && tupleA.66 == tupleB.66 && tupleA.67 == tupleB.67
}

func == (tupleA: Bindings.UInt8Tuple12, tupleB: Bindings.UInt8Tuple12) -> Bool {
	return tupleA.0 == tupleB.0 && tupleA.1 == tupleB.1 && tupleA.2 == tupleB.2 && tupleA.3 == tupleB.3
		&& tupleA.4 == tupleB.4 && tupleA.5 == tupleB.5 && tupleA.6 == tupleB.6 && tupleA.7 == tupleB.7
		&& tupleA.8 == tupleB.8 && tupleA.9 == tupleB.9 && tupleA.10 == tupleB.10 && tupleA.11 == tupleB.11
}

func == (tupleA: Bindings.UInt8Tuple80, tupleB: Bindings.UInt8Tuple80) -> Bool {
	return tupleA.0 == tupleB.0 && tupleA.1 == tupleB.1 && tupleA.2 == tupleB.2 && tupleA.3 == tupleB.3
		&& tupleA.4 == tupleB.4 && tupleA.5 == tupleB.5 && tupleA.6 == tupleB.6 && tupleA.7 == tupleB.7
		&& tupleA.8 == tupleB.8 && tupleA.9 == tupleB.9 && tupleA.10 == tupleB.10 && tupleA.11 == tupleB.11
		&& tupleA.12 == tupleB.12 && tupleA.13 == tupleB.13 && tupleA.14 == tupleB.14 && tupleA.15 == tupleB.15
		&& tupleA.16 == tupleB.16 && tupleA.17 == tupleB.17 && tupleA.18 == tupleB.18 && tupleA.19 == tupleB.19
		&& tupleA.20 == tupleB.20 && tupleA.21 == tupleB.21 && tupleA.22 == tupleB.22 && tupleA.23 == tupleB.23
		&& tupleA.24 == tupleB.24 && tupleA.25 == tupleB.25 && tupleA.26 == tupleB.26 && tupleA.27 == tupleB.27
		&& tupleA.28 == tupleB.28 && tupleA.29 == tupleB.29 && tupleA.30 == tupleB.30 && tupleA.31 == tupleB.31
		&& tupleA.32 == tupleB.32 && tupleA.33 == tupleB.33 && tupleA.34 == tupleB.34 && tupleA.35 == tupleB.35
		&& tupleA.36 == tupleB.36 && tupleA.37 == tupleB.37 && tupleA.38 == tupleB.38 && tupleA.39 == tupleB.39
		&& tupleA.40 == tupleB.40 && tupleA.41 == tupleB.41 && tupleA.42 == tupleB.42 && tupleA.43 == tupleB.43
		&& tupleA.44 == tupleB.44 && tupleA.45 == tupleB.45 && tupleA.46 == tupleB.46 && tupleA.47 == tupleB.47
		&& tupleA.48 == tupleB.48 && tupleA.49 == tupleB.49 && tupleA.50 == tupleB.50 && tupleA.51 == tupleB.51
		&& tupleA.52 == tupleB.52 && tupleA.53 == tupleB.53 && tupleA.54 == tupleB.54 && tupleA.55 == tupleB.55
		&& tupleA.56 == tupleB.56 && tupleA.57 == tupleB.57 && tupleA.58 == tupleB.58 && tupleA.59 == tupleB.59
		&& tupleA.60 == tupleB.60 && tupleA.61 == tupleB.61 && tupleA.62 == tupleB.62 && tupleA.63 == tupleB.63
		&& tupleA.64 == tupleB.64 && tupleA.65 == tupleB.65 && tupleA.66 == tupleB.66 && tupleA.67 == tupleB.67
		&& tupleA.68 == tupleB.68 && tupleA.69 == tupleB.69 && tupleA.70 == tupleB.70 && tupleA.71 == tupleB.71
		&& tupleA.72 == tupleB.72 && tupleA.73 == tupleB.73 && tupleA.74 == tupleB.74 && tupleA.75 == tupleB.75
		&& tupleA.76 == tupleB.76 && tupleA.77 == tupleB.77 && tupleA.78 == tupleB.78 && tupleA.79 == tupleB.79
}

func == (tupleA: Bindings.UInt16Tuple32, tupleB: Bindings.UInt16Tuple32) -> Bool {
	return tupleA.0 == tupleB.0 && tupleA.1 == tupleB.1 && tupleA.2 == tupleB.2 && tupleA.3 == tupleB.3
		&& tupleA.4 == tupleB.4 && tupleA.5 == tupleB.5 && tupleA.6 == tupleB.6 && tupleA.7 == tupleB.7
		&& tupleA.8 == tupleB.8 && tupleA.9 == tupleB.9 && tupleA.10 == tupleB.10 && tupleA.11 == tupleB.11
		&& tupleA.12 == tupleB.12 && tupleA.13 == tupleB.13 && tupleA.14 == tupleB.14 && tupleA.15 == tupleB.15
		&& tupleA.16 == tupleB.16 && tupleA.17 == tupleB.17 && tupleA.18 == tupleB.18 && tupleA.19 == tupleB.19
		&& tupleA.20 == tupleB.20 && tupleA.21 == tupleB.21 && tupleA.22 == tupleB.22 && tupleA.23 == tupleB.23
		&& tupleA.24 == tupleB.24 && tupleA.25 == tupleB.25 && tupleA.26 == tupleB.26 && tupleA.27 == tupleB.27
		&& tupleA.28 == tupleB.28 && tupleA.29 == tupleB.29 && tupleA.30 == tupleB.30 && tupleA.31 == tupleB.31
}


