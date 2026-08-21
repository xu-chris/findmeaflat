defmodule FindMeAFlat.Crawling.Scheduler do
  @moduledoc """
  Decides which watches are due and enqueues one crawl job for each.

  Empty in S1; S8 implements it. It is named here because the cron entry that will
  call it, and the queues it will enqueue into, are configured in this slice.

  `FindMeAFlat.Crawling` owns sequencing and no data: no Ash resource, no `Repo`
  call, no `Ash.read/3` in this namespace. It calls domain code interfaces only.
  """
end
