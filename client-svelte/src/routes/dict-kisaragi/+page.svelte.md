<script>
  import kisaragi_dict from "$lib/kisaragi_dict.json"
  import RecentWordList from "$lib/components/RecentWordList.svelte"
</script>

<svelte:head>
  <title>字典 | Kisaragi's Extras</title>
</svelte:head>

# 字典：Kisaragi's extras

我希望能夠有個地方能夠收錄日常使用但卻沒有人依實際使用狀況記錄下來的詞。

當一個語言的絕大部分使用者使用一種讀音，而字典卻標註另一種，錯誤的是不正視現實的字典，不是說話的人。見：「骰子」、「收件匣」、「丼」、「熟悉」、「拖曳」。

我很感謝教育部各詞典編撰後公開供任何人使用。教育部詞典的編撰者們做的是我無法想像自己能有能力做到的事。

雖說如此，我還是認為教育部詞典的編撰方針與現實脫節了。在大多人都不會看得懂「色子」的情況下堅持「骰子」唸作「ㄕㄞˇ ㄗ˙」是混同「色子」的音；電郵系統出現至今數十年依然沒有收錄「寄件匣」、「收件匣」等等，我認為這是不合理的。

因此我嘗試製作這個「字典」，裡面包含了我所寫的定義。

目前共有 {kisaragi_dict.length} 條：

<RecentWordList />