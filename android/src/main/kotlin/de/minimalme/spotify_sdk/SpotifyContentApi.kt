package de.minimalme.spotify_sdk

import android.util.Log
import com.google.gson.Gson
import com.spotify.android.appremote.api.ContentApi
import com.spotify.android.appremote.api.SpotifyAppRemote
import com.spotify.protocol.types.ListItem
import io.flutter.plugin.common.MethodChannel

/**
 *@date 20250905
 *@author kuang
 */
class SpotifyContentApi(spotifyAppRemote: SpotifyAppRemote?, result: MethodChannel.Result): BaseSpotifyApi(spotifyAppRemote, result) {
    private val contentApi = spotifyAppRemote?.contentApi

    /**
     * 获取推荐内容列表
     * @param contentType 获取的推荐内容类型 @see[com.spotify.android.appremote.api.ContentApi.ContentType]
     * @param limit 返回数量
     *
     */
    fun getRecommendedContentItems(contentType: String?){

        if(contentApi==null){
            result.error("getRecommendedContentItems","spotifyAppRemote.contentApi is null",null)
            return
        }

        contentApi.getRecommendedContentItems(contentType)?.setResultCallback { listItems ->
            listItems.items.forEach {
                Log.d(javaClass.simpleName,"listItems.items${it.toString()}")}
            Log.d(javaClass.simpleName,listItems.toString())
            result.success(Gson().toJson(listItems))
        }?.setErrorCallback {
            result.error("getRecommendedContentItems",it.message,null)
        }
    }

    /**
     * 获取listitem子项
     * @param item 访问其子项的内容项
     * @param perpage 返回数量
     * @param offset 要获取的第一个子项的索引
     */
    fun getChildrenOfItem(item:ListItem,perpage:Int = 20, offset:Int = 0){
        if(contentApi==null){
            result.error("getChildrenOfItem","spotifyAppRemote.contentApi is null",null)
            return
        }

        Log.d(javaClass.simpleName,"getChildrenOfItem.perpage：${perpage}.offset:$offset")
        contentApi.getChildrenOfItem(item,perpage,offset)?.setResultCallback {
            Log.d(javaClass.simpleName,"getChildrenOfItem：${it.toString()}")
            result.success(Gson().toJson(it))
        }?.setErrorCallback {
            result.error("getChildrenOfItem",it.message,null)
        }
    }
    /**
     * 播放内容项
     * @param item 播放的内容项
     */
    fun playContentItem(item:ListItem){
        if(contentApi==null){
            result.error("playContentItem","spotifyAppRemote.contentApi is null",null)
            return
        }

        contentApi.playContentItem(item).setResultCallback {
            result.success(true)
        }.setErrorCallback{
            result.error("playContentItem",it.message,null)
        }
    }
}