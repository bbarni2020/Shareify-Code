package com.shareify.code.models

sealed class AIAction(val type: ActionType) {
    sealed class ActionType {
        data class Edit(val old: String, val new: String) : ActionType()
        data class Rewrite(val file: String, val content: String) : ActionType()
        data class Insert(val after: String, val content: String) : ActionType()
        data class Terminal(val command: String, val reason: String) : ActionType()
        data class Search(val pattern: String, val reason: String) : ActionType()
    }

    companion object {
        fun parseActions(text: String): List<AIAction> {
            val actions = mutableListOf<AIAction>()
            
            val editPattern = Regex("""<EDIT>\s*<OLD>(.*?)</OLD>\s*<NEW>(.*?)</NEW>\s*</EDIT>""", RegexOption.DOT_MATCHES_ALL)
            editPattern.findAll(text).forEach { match ->
                val old = match.groupValues[1].trim()
                val new = match.groupValues[2].trim()
                actions.add(EditAction(old, new))
            }
            
            val rewritePattern = Regex("""<REWRITE>\s*<FILE>(.*?)</FILE>\s*<CONTENT>(.*?)</CONTENT>\s*</REWRITE>""", RegexOption.DOT_MATCHES_ALL)
            rewritePattern.findAll(text).forEach { match ->
                val file = match.groupValues[1].trim()
                val content = match.groupValues[2].trim()
                actions.add(RewriteAction(file, content))
            }
            
            val insertPattern = Regex("""<INSERT>\s*<AFTER>(.*?)</AFTER>\s*<CONTENT>(.*?)</CONTENT>\s*</INSERT>""", RegexOption.DOT_MATCHES_ALL)
            insertPattern.findAll(text).forEach { match ->
                val after = match.groupValues[1].trim()
                val content = match.groupValues[2].trim()
                actions.add(InsertAction(after, content))
            }
            
            val terminalPattern = Regex("""<TERMINAL>\s*<COMMAND>(.*?)</COMMAND>\s*<REASON>(.*?)</REASON>\s*</TERMINAL>""", RegexOption.DOT_MATCHES_ALL)
            terminalPattern.findAll(text).forEach { match ->
                val command = match.groupValues[1].trim()
                val reason = match.groupValues[2].trim()
                actions.add(TerminalAction(command, reason))
            }
            
            val searchPattern = Regex("""<SEARCH>\s*<PATTERN>(.*?)</PATTERN>\s*<REASON>(.*?)</REASON>\s*</SEARCH>""", RegexOption.DOT_MATCHES_ALL)
            searchPattern.findAll(text).forEach { match ->
                val pattern = match.groupValues[1].trim()
                val reason = match.groupValues[2].trim()
                actions.add(SearchAction(pattern, reason))
            }
            
            return actions
        }
    }
}

class EditAction(val old: String, val new: String) : AIAction(ActionType.Edit(old, new))
class RewriteAction(val file: String, val content: String) : AIAction(ActionType.Rewrite(file, content))
class InsertAction(val after: String, val content: String) : AIAction(ActionType.Insert(after, content))
class TerminalAction(val command: String, val reason: String) : AIAction(ActionType.Terminal(command, reason))
class SearchAction(val pattern: String, val reason: String) : AIAction(ActionType.Search(pattern, reason))
