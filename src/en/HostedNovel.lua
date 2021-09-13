-- {"id":93083,"ver":"1.0.13","libVer":"1.0.0","author":"jpdasma","dep":[]}
local baseURL = "https://hostednovel.com"

local function shrinkURL(url)
	return url:gsub(baseURL, "")
end

local function text(v)
	return v:text()
end

return {
	id = 93083,
	name = "Hosted Novel",
	baseURL = baseURL,
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/NMTranslations.png",
	hasSearch = false,
	listings = {
		Listing("Projects", false, function()
			local doc = GETDocument(baseURL .. "/novels")

			return map(doc:select("div.row.py-3"), function(v)
				local novel = Novel()
				local title = v:selectFirst("div.col-md-6.col-lg-5"):selectFirst("a")
				novel:setTitle(title:text())
				novel:setLink(shrinkURL(title:attr("href")))
				return novel
			end)
		end)
	},

	parseNovel = function(url, loadChapters)
		local document = GETDocument(baseURL .. url)

		local info = NovelInfo {
			title = document:selectFirst("h1.text-center"):text(),
			imageURL = baseURL .. document:selectFirst("img.cover-image"):attr("src"),
		}

		if loadChapters then
			--- @param chaptersDocument Document
			local function parseChapters(chaptersDocument)
				return map(chaptersDocument:select("div.row.py-3"), function(article)
					local titleElement = article:selectFirst("a")
					return NovelChapter {
						title = titleElement:text(),
						link = shrinkURL(titleElement:attr("href")),
						release = article:selectFirst("div.time"):text()
					}
				end)
			end

			local chapters = {}

			local chapterList = map(document:select("div.chaptergroup"), function(c)
				return c:attr("data-id")
			end)

			for i = 1, #chapterList, 1 do
				local chaptersSection = GETDocument(baseURL .. url .. '/chapters/' .. chapterList[i])
				chapters[i] = parseChapters(chaptersSection)
			end

			chapters = flatten(chapters)

			local o = 1
			for i = #chapters, 1, -1 do
				chapters[i]:setOrder(o)
				o = o + 1
			end

			local chaptersList = AsList(chapters)
			info:setChapters(chaptersList)
		end

		return info
	end,

	getPassage = function(url)
		local doc = GETDocument(baseURL .. url:gsub("//", ""))
		return table.concat(map(doc:selectFirst("div#chapter.card-body.chapter"):select("p"), text), "\n")
	end
}
