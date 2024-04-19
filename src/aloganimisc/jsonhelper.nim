import std/json

func flattenJsonDict*(node: JsonNode, idKey, childKey: string): JsonNode =
    var flattenedRes = newJObject()
    proc flattenJsonDict_helper(item: JsonNode, parentKey = "") =
        if item.kind == JObject:
            let newKey = (if parentKey != "": parentKey & "/" else: "") & item[idKey].getStr()
            let child = item.getOrDefault(childKey)
            if child != nil:
                item.delete(childKey)
                flattenedRes[newKey] = item
                flattenJsonDict_helper(child, newKey)
            else:
                flattenedRes[newKey] = item
        elif item.kind == JArray:
            for child in item.items():
                flattenJsonDict_helper(child, parentKey)
    flattenJsonDict_helper(node)
    return flattenedRes