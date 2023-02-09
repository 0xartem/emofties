import { gql, useQuery } from "@apollo/client"
import { useEffect, useState } from "react"
import ErrorPage from "../../pages/ErrorPage"

import { Emofty } from "../../../../subgraph-goerli/generated/schema"
import EmoftyCard from "../emofties/EmoftyCard"

const EMOFTIES = gql`
    query {
        emofties(orderBy: timestamp, orderDirection: desc) {
            # id
            emoftyId
            sender
            coreEmotion
            emotionShade
            receiver
            memo
            # timestamp
            # blockNumber
            # blockTimestamp
            # transactionHash
        }
    }
`

const Feed = () => {
    const [emoftiesCol, setEmoftiesCol] = useState<Emofty[]>([])
    const { loading, error, data } = useQuery(EMOFTIES)

    useEffect(() => {
        if (data) {
            const { emofties } = data
            setEmoftiesCol(emofties)
        }
    }, [data])
    return (
        <div>
            {loading && <span>Loading Emofties...</span>}
            {error && <span>{error?.message}</span>}
            {emoftiesCol && (
                <div
                    // className="grid grid-cols-3 gap-10 justify-items-center"
                    className="flex flex-col gap-10 items-center"
                >
                    {emoftiesCol.map((emofty) => (
                        <EmoftyCard emofty={emofty} />
                    ))}
                </div>
            )}
        </div>
    )
}

export default Feed