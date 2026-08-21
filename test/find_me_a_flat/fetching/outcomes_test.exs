defmodule FindMeAFlat.Fetching.OutcomesTest do
  @moduledoc """
  The load-bearing assertions here are the two cancels.

  Oban's default `max_attempts` is 20. Against a portal that answers 401 behind an
  AWS WAF challenge, or 410 because the URL was retired, a retryable outcome means
  nineteen further requests to a site that is actively telling us to stop — per
  watch, per cycle. That is how a 410 becomes an IP ban. So `:challenged` and
  `:gone` are not "an error we saw"; they are a decision to stop asking.

  The second one is that a 200 is not a success. `CRAWL-DIAGNOSIS.md` records
  Berlin's WFS returning HTTP 200 with a maintenance page, and a WAF is equally free
  to answer 200 with a challenge. Detection reads the body, not just the status.
  """

  use ExUnit.Case, async: true

  alias FindMeAFlat.Fetching
  alias FindMeAFlat.Fetching.Page
  alias FindMeAFlat.Fetching.Transport.Stub

  setup context do
    slug = "outcomes-#{:erlang.phash2(context.test)}"
    :ok = Fetching.pace([{slug, 0}])
    %{slug: slug}
  end

  describe "fetch/2 turns a response into an outcome" do
    test "a whole page under 200 is a Page", %{slug: slug} do
      assert {:ok, %Page{} = page} = Fetching.fetch(slug, url("/ok"))

      assert page.status == 200
      assert page.url == url("/ok")
      assert page.final_url == url("/ok")
      assert page.body =~ "Wohnungen mieten"
      assert %DateTime{} = page.fetched_at
    end

    test "the URL a redirect chain ended on is the one the Page carries", %{slug: slug} do
      assert {:ok, %Page{url: requested, final_url: final}} =
               Fetching.fetch(slug, url("/redirected"))

      assert requested == url("/redirected")
      assert final == url("/ok")
    end

    test "a 401 behind an AWS WAF challenge is :challenged", %{slug: slug} do
      assert {:error, :challenged} = Fetching.fetch(slug, url("/challenge/aws-waf"))
    end

    test "the same challenge body under a 200 is still :challenged", %{slug: slug} do
      # The status alone would read as success. The markers are what give it away.
      assert Stub.aws_waf_challenge() =~ "awswaf"
      assert Stub.aws_waf_challenge() =~ "Ich bin kein Roboter"

      assert {:error, :challenged} = Fetching.fetch(slug, url("/challenge/aws-waf-under-200"))
    end

    test "a DataDome block page is :challenged", %{slug: slug} do
      assert {:error, :challenged} = Fetching.fetch(slug, url("/challenge/datadome"))
    end

    test "a 410 is :gone", %{slug: slug} do
      assert {:error, :gone} = Fetching.fetch(slug, url("/gone"))
    end

    test "a 404 is :not_found", %{slug: slug} do
      assert {:error, :not_found} = Fetching.fetch(slug, url("/not-found"))
    end

    test "a 429 is :rate_limited", %{slug: slug} do
      assert {:error, :rate_limited} = Fetching.fetch(slug, url("/rate-limited"))
    end

    test "a transport timeout is :timeout", %{slug: slug} do
      assert {:error, :timeout} = Fetching.fetch(slug, url("/timeout"))
    end

    test "a refused connection is :transport_error", %{slug: slug} do
      assert {:error, :transport_error} = Fetching.fetch(slug, url("/refused"))
    end

    test "a body cut off mid-tag is :transport_error, not a Page", %{slug: slug} do
      # A truncated 200 parses to zero listings, which the health state would read
      # as "the portal broke". It did not; the response did.
      assert {:error, :transport_error} = Fetching.fetch(slug, url("/truncated"))
    end

    test "a 500 is :transport_error", %{slug: slug} do
      assert {:error, :transport_error} = Fetching.fetch(slug, url("/server-error"))
    end

    test "no response produces a reason outside the six declared ones", %{slug: slug} do
      declared = ~w(challenged gone not_found rate_limited timeout transport_error)a

      for path <- error_paths() do
        assert {:error, reason} = Fetching.fetch(slug, url(path))
        assert reason in declared, "#{path} produced #{inspect(reason)}"
      end
    end
  end

  describe "disposition/1 declares what a worker does next" do
    test ":challenged cancels, because retrying is the harm" do
      assert Fetching.disposition({:error, :challenged}) == :cancel
    end

    test ":gone cancels, because the URL is not coming back" do
      assert Fetching.disposition({:error, :gone}) == :cancel
    end

    test ":not_found cancels, for the same reason as :gone" do
      # The search URL is a stored configuration value. No number of retries edits
      # a row, and twenty 404s a cycle are twenty requests spent on nothing.
      assert Fetching.disposition({:error, :not_found}) == :cancel
    end

    test ":rate_limited snoozes rather than retrying immediately" do
      assert {:snooze, seconds} = Fetching.disposition({:error, :rate_limited})
      assert seconds >= 60
    end

    test ":timeout retries" do
      assert Fetching.disposition({:error, :timeout}) == :retry
    end

    test ":transport_error retries" do
      assert Fetching.disposition({:error, :transport_error}) == :retry
    end

    test ":gated snoozes for as long as the gate asked for" do
      assert Fetching.disposition({:error, :gated, 4_200}) == {:snooze, 5}
    end

    test "a gate hint under a second still snoozes for a whole second" do
      assert Fetching.disposition({:error, :gated, 1}) == {:snooze, 1}
    end

    test "no fetch error is left without a disposition", %{slug: slug} do
      for path <- error_paths() do
        error = Fetching.fetch(slug, url(path))
        disposition = Fetching.disposition(error)

        assert disposition in [:cancel, :retry] or match?({:snooze, _}, disposition),
               "#{path} produced #{inspect(error)}, which has no disposition"
      end
    end
  end

  describe "the request a portal actually receives" do
    test "carries a current browser header set asking for German", %{slug: slug} do
      assert {:ok, %Page{body: sent}} = Fetching.fetch(slug, url("/echo"))

      assert sent =~ "accept-language: de-DE"
      assert sent =~ "sec-fetch-mode: navigate"
      assert sent =~ "upgrade-insecure-requests: 1"
    end

    test "does not send the 2017 Chrome the Node crawler sent", %{slug: slug} do
      assert {:ok, %Page{body: sent}} = Fetching.fetch(slug, url("/echo"))

      assert [user_agent] = Regex.run(~r/^user-agent: .+$/m, sent)
      assert user_agent =~ "Chrome/"
      refute user_agent =~ "Chrome/60"
      assert [_, major] = Regex.run(~r{Chrome/(\d+)}, user_agent)
      assert String.to_integer(major) >= 130
    end

    test "replays the cookies the portal set on the previous response", %{slug: slug} do
      assert {:ok, %Page{}} = Fetching.fetch(slug, url("/set-cookie"))
      assert {:ok, %Page{body: sent}} = Fetching.fetch(slug, url("/echo"))

      assert [cookie] = Regex.run(~r/^cookie: .+$/m, sent)
      assert cookie =~ "datadome=abc123"
      assert cookie =~ "session=xyz789"
      refute cookie =~ "Max-Age"
      refute cookie =~ "HttpOnly"
    end

    test "keeps one portal's jar out of another portal's requests", %{slug: slug} do
      other = "#{slug}-neighbour"
      :ok = Fetching.pace([{other, 0}])

      assert {:ok, %Page{}} = Fetching.fetch(slug, url("/set-cookie"))
      assert {:ok, %Page{body: sent}} = Fetching.fetch(other, url("/echo"))

      refute sent =~ "datadome=abc123"
    end

    test "sends no cookie header before a portal has set one", %{slug: slug} do
      assert {:ok, %Page{body: sent}} = Fetching.fetch(slug, url("/echo"))

      refute sent =~ ~r/^cookie: /m
    end
  end

  defp url(path), do: Stub.host() <> path

  defp error_paths do
    ~w(/challenge/aws-waf /challenge/aws-waf-under-200 /challenge/datadome /gone
       /not-found /rate-limited /timeout /refused /truncated /server-error)
  end
end
