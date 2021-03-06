--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}

import Hakyll

--------------------------------------------------------------------------------
config :: Configuration
config = defaultConfiguration
  { destinationDirectory = "docs"
  }

main :: IO ()
main = hakyllWith config $ do
  match "images/*" $ do
    route idRoute
    compile copyFileCompiler

  match "css/*" $ do
    route idRoute
    compile compressCssCompiler

  match "posts/*" $ do
    route $ setExtension "html"
    compile $ do
      let pageCtx =
            field "recent_posts" (\_ -> recentPostList)
              `mappend` postCtx

      pandocCompiler
        >>= loadAndApplyTemplate "templates/post.html" postCtx
        >>= loadAndApplyTemplate "templates/default.html" pageCtx
        >>= relativizeUrls

  match (fromList ["about.md", "contact.md", "recommended-readings.md"]) $ do
    route $ setExtension "html"
    compile $ do
      let pagesCtx =
            field "recent_posts" (\_ -> recentPostList)
              `mappend` constField "title" siteTitle
              `mappend` constField "site_desc" siteDesc
              `mappend` defaultContext

      pandocCompiler
        >>= loadAndApplyTemplate "templates/page.html" defaultContext
        >>= loadAndApplyTemplate "templates/default.html" pagesCtx
        >>= relativizeUrls

  match "index.html" $ do
    route idRoute
    compile $ do
      posts <- recentFirst =<< loadAll "posts/*"
      let indexCtx =
            field "recent_posts" (\_ -> recentPostList)
              `mappend` listField "posts" postCtx (return posts)
              `mappend` constField "title" siteTitle
              `mappend` constField "site_desc" siteDesc
              `mappend` defaultContext

      getResourceBody
        >>= applyAsTemplate indexCtx
        >>= loadAndApplyTemplate "templates/default.html" indexCtx
        >>= relativizeUrls

  match "templates/*" $ compile templateBodyCompiler

--------------------------------------------------------------------------------
-- Metadata
postCtx :: Context String
postCtx =
  dateField "date" "%B %e, %Y"
    `mappend` constField "site_desc" siteDesc
    `mappend` defaultContext

siteDesc :: String
siteDesc = "Just sharing things"

siteTitle :: String
siteTitle = "Gauthier's Blog"

--------------------------------------------------------------------------------
-- Recent Posts
recentPosts :: Compiler [Item String]
recentPosts = do
  identifiers <- getMatches "posts/*"
  return [Item identifier "" | identifier <- identifiers]

recentPostList :: Compiler String
recentPostList = do
  posts <- fmap (take 10) . recentFirst =<< recentPosts
  itemTpl <- loadBody "templates/listitem.html"
  list <- applyTemplateList itemTpl defaultContext posts
  return list
