import { keccak256, parseBytes32String, toUtf8Bytes } from "ethers/lib/utils.js"
import { Emofty } from "../../../../subgraph-goerli/generated/schema"

type CoreEmotion = "JOY" | "FEAR" | "ANGER" | "SADNESS" | "DISGUST" | "LOVE"

const coreEmotionsMap = (() => {
    const emotionsMap: Map<string, string> = new Map()
    emotionsMap.set(keccak256(toUtf8Bytes("JOY")), "JOY")
    emotionsMap.set(keccak256(toUtf8Bytes("FEAR")), "FEAR")
    emotionsMap.set(keccak256(toUtf8Bytes("ANGER")), "ANGER")
    emotionsMap.set(keccak256(toUtf8Bytes("SADNESS")), "SADNESS")
    emotionsMap.set(keccak256(toUtf8Bytes("DISGUST")), "DISGUST")
    emotionsMap.set(keccak256(toUtf8Bytes("LOVE")), "LOVE")
    return emotionsMap
})()

type Props = {
    emofty: Emofty
    isArweave?: boolean
}
const EmoftyCard = ({ emofty, isArweave = false }: Props) => {
    let parsedEmotionShade = "Emotion Display Error"
    try {
        if (emofty.emotionShade) {
            if (isArweave) {
                parsedEmotionShade = emofty.emotionShade.toString()
            } else {
                parsedEmotionShade = parseBytes32String(emofty.emotionShade)
            }
        }
    } catch (err) {
        console.error("parseBytes32String error", err)
    }

    const coreEmotionStr = coreEmotionsMap.get(emofty.coreEmotion.toString())
    let shadowColor
    switch (coreEmotionStr) {
        case "JOY":
            shadowColor = "shadow-yellow-200"
            break
        case "FEAR":
            shadowColor = "shadow-purple-400"
            break
        case "ANGER":
            shadowColor = "shadow-red-400"
            break
        case "SADNESS":
            shadowColor = "shadow-cyan-500"
            break
        case "DISGUST":
            shadowColor = "shadow-green-300"
            break
        case "LOVE":
            shadowColor = "shadow-pink-300"
            break
        default:
            shadowColor = "shadow-slate-500"
    }

    return (
        <div className={`card w-96 bg-base-100 shadow-xl ${shadowColor}`}>
            <figure>
                <img
                    src="/assets/emotions-social-graph.jpg"
                    alt="Emofty Image"
                />
            </figure>
            <div className="card-body">
                <div className="badge badge-outline">author</div>
                <div className="badge badge-primary gap-2">{emofty.sender}</div>
                <h2 className="card-title">
                    {parsedEmotionShade}
                    <div className={`badge badge-secondary`}>
                        {coreEmotionsMap.get(emofty.coreEmotion.toString())}
                    </div>
                </h2>
                <div className="badge badge-outline">memo</div>
                <p>{emofty.memo}</p>
                <div className="card-actions">
                    {/* <div className="badge badge-outline">{emofty.emoftyId}</div> */}
                    {/* <div className="badge badge-outline">{emofty.receiver}</div> */}
                </div>
            </div>
        </div>
    )
}

export default EmoftyCard