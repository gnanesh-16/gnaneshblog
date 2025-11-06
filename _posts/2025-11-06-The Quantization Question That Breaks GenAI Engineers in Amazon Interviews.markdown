---
layout: post
title: "The Quantization Question That Breaks GenAI Engineers in Amazon Interviews"
date: 2025-11-06 20:30:00 +0530
categories: genai-engineering
tags: [quantization, llm, genai, amazon, interviews, production-deployment, deep-learning, aws, machine-learning]
author: Gnanesh Balusa
permalink: /:categories/:year/:month/:day/:title.html
description: "Amazon asks you to deploy a 70B LLM for production systems. 4-bit or 8-bit quantization? Most GenAI engineers freeze. Here's what separates the candidates who actually know their stuff from those who bomb the interview."
---

You're sitting across from an interviewer at Amazon. The room's quiet except for the keyboard clicks. Then they drop it:

"We're building a recommendation engine using a 70B parameter LLM on AWS. Should we use 4-bit or 8-bit quantization? Justify your choice. Also, which EC2 instance types would you recommend?"

Your heart skips. You know what quantization is, right? Reduce the model size. Cool. But that answer? That's a junior developer answer. And you just watched half the room bomb this exact question.

Here's the thing most candidates fumble because they only know the surface-level definition. "Quantization reduces model size." That's like saying a car is something with wheels. Technically true, but useless.

The engineers who get the offer? They understand that quantization is about tradeoffs. Deep ones. The kind that determine whether your model runs efficiently on AWS SageMaker or ends up costing the company thousands in wasted compute every month.

## The Five Things You Need to Know Cold

### 1. The Precision-Performance Tradeoff: The Fundamental Difference

This is where most people get it wrong. They think smaller always means better. Nope.

**8-bit (INT8)** maintains near-identical accuracy. We're talking performance degradation under 1% on most tasks. It uses linear quantization, which means the conversion is straightforward:

```
Q = round(scale × W + zero_point)
```

That linearity matters. It's predictable. If you're running recommendation systems or search ranking at Amazon scale, that 1% degradation is almost invisible to users.

**4-bit (INT4/NF4)** trades accuracy for efficiency. You're looking at 2-5% performance degradation depending on the architecture. It uses non-linear quantization specifically something called NormalFloat4 which tries hard to preserve the distribution of weights, but it's fighting an uphill battle. Ever wonder why companies like Google with their LLaMA and Meta use 4-bit more often? They've got the infrastructure and validation pipelines to catch quality issues. You might not.

Here's the brutal truth that interviewers at Amazon want to hear: **8-bit is production-safe. 4-bit requires extensive validation and monitoring in production.**

For a recommendation engine? Getting recommendations wrong kills engagement. Kill engagement and revenue drops. That's the conversation you need to have.

### 2. The Memory Footprint: Where 90% of Engineers Go Wrong

Everyone thinks they understand this part. They don't.

Most people say "4-bit is 2x smaller than 8-bit." Wrong move. Let me show you the actual numbers that matter for AWS deployment.

Starting with **FP32 (full precision)**: a 70B model takes up 280GB. You'd need multiple `p4d.24xlarge` instances just for storage.

**INT8** gets you to 70GB. That's 4x compression. Nice. You're looking at a single `p3.8xlarge` or smaller `g4dn` instance family.

**INT4** gets you to 35GB. That's 8x compression. Even nicer, right? Here's where people get excited and make mistakes.

But you're not just storing the weights. You've still got overhead. Serious overhead. The KV cache (that's the key-value pairs stored during inference), the activations as data flows through the model, attention buffers... that all adds up fast.

Real-world 70B INT4 deployment on SageMaker? You're looking at **48-60GB minimum**. Not 35GB. Not even close.

So when your infrastructure team suggests a `g4dn.xlarge` with 24GB, you nod politely and then explain why INT4 on that hardware is going to bottleneck your inference. You'd be running single-batch inference at best. At Amazon scale with millions of users? That's a non-starter.

An `p3.8xlarge` with 32GB? A `p4d.24xlarge`? Those fit a 70B INT8 model comfortably with room to breathe for batches of 8-16 concurrent requests. That changes the economics of your entire SageMaker deployment and your cost per inference.

### 3. The Quantization Method: The Hidden Production Killer

Here's what separates junior engineers from senior ones. Junior devs pick a quantization method and hope it works. Senior engineers know the methods matter more than the bit depth.

**Post-Training Quantization (PTQ)** is fast. You're talking hours, maybe a day. It works reliably for 8-bit. Companies like Google DeepMind often use PTQ for their initial experiments. For 4-bit? The quality bounces all over the place. Sometimes it's fine. Sometimes it's a disaster. And you won't know which until you're in production.

**GPTQ and AWQ** (these are advanced PTQ methods developed by researchers at UC Berkeley and MIT) are the industry standard for 4-bit LLMs. They use weight-only quantization combined with calibration. But here's the catch you need a representative calibration dataset. Not just any data. Representative data that actually looks like what your model will see in production.

At Amazon, if you're building a recommendation engine, your calibration set needs to look like real user queries and product catalogs. Get this wrong and your model will fail spectacularly when it sees real data. Your recommendation engine starts suggesting random products, and suddenly you've got a business problem, not just a technical problem.

**Quantization-Aware Training (QAT)** is the gold standard. You're training the model knowing it'll be quantized, so the weights adapt during training. Companies like Microsoft with their Phi models use QAT extensively. But this costs compute. Days or weeks of GPU time. It's expensive. It's rarely done unless the stakes are genuinely high.

For a recommendation system at Amazon scale? The stakes are high. But the question becomes: do you have the compute budget for QAT? If yes, do it. If no, stick with 8-bit and sleep better at night.

### 4. The Inference Speed Tradeoff: The Counterintuitive Reality

Everyone assumes 4-bit is faster because it's smaller. Welcome to the world where intuition breaks.

**8-bit has native GPU support.** Your Tensor Cores (the specialized hardware on modern GPUs like those on AWS `p3` and `p4d` instances) can handle `INT8` operations natively. Matrix multiplication runs at maximum speed. You get 1.5-2x throughput compared to `FP16` (half precision). This is why NVIDIA pushed so hard on INT8 support in Ampere and Hopper architectures.

**4-bit doesn't have that native support** on most hardware. The GPU has to dequantize the weights back to `FP16` before it can do the actual computation. That dequantization step costs time and bandwidth. You're memory-bandwidth bound, not compute-bound. The counterintuitive reality? 4-bit often isn't faster despite being smaller.

In some cases, 4-bit is actually slower than 8-bit for inference because of all that dequantization overhead. This is why companies like Google Cloud and Azure often default to 8-bit for latency-critical workloads.

That matters when you're trying to serve recommendations in real-time. Every millisecond counts when you've got users waiting.

### 5. The Deployment Reality: The Costs Nobody Talks About

This is where theory meets infrastructure, and where most candidates fall apart in interviews.

**8-bit scenario:** A `p3.8xlarge` on AWS fits a 70B model comfortably. You can run batch sizes of 8-16. Multiple requests can be served together. Your cost per inference goes down significantly. Your latency stays reasonable even under load. Monthly cost for on-demand: around $12,000. Predictable. Manageable.

**4-bit scenario:** A `g4dn.12xlarge` with 48GB can technically run a 70B model. The word "technically" does a lot of heavy lifting here. You're looking at batch size 1-4 maximum. One or two requests at a time, essentially. Your throughput tanks. Your cost per inference skyrockets. You might save on compute hours, but you need way more instances to handle the same load. Monthly cost suddenly becomes $40,000+ because you're running more instances at lower utilization.

The math gets harsh fast. If you need to serve millions of recommendations per day (which Amazon definitely does), 4-bit on smaller EC2 instances isn't happening. You'd need a farm of high-end instances anyway, and suddenly your "cost savings" from quantization disappear into AWS bills.

This is exactly the kind of thinking that separates people who understand cloud economics from those who just understand machine learning.

## So When Do You Actually Pick Each One?

**Go with 8-bit when:**

- Latency is critical (recommendations, search ranking, real-time predictions)
- You need batch inference with reasonable throughput
- Your team doesn't have extensive ML ops expertise for validation
- You want predictable AWS costs
- Production reliability matters more than squeezing every last bit of efficiency

**Go with 4-bit when:**

- Extreme memory constraints force your hand
- Cost per inference is the only metric that matters
- You can tolerate 2-5% quality degradation
- You're using GPTQ or AWQ with extensive calibration
- Your team has time and resources to validate thoroughly in staging
- You're at a company like Google or Meta with massive ML infrastructure

## The Answer They Want to Hear at Amazon

So you're in that interview. What do you actually say?

"For an Amazon recommendation engine, I'd go with 8-bit quantization. Here's why:

First, the accuracy hit. 8-bit gives us less than 1% degradation. In recommendations, that's acceptable. We might lose one or two good suggestions per user session, which is barely noticeable. 4-bit's 2-5% degradation means we might be recommending significantly less relevant products. That kills engagement and revenue.

Second, the AWS hardware reality. A `p3.8xlarge` or `p4d.24xlarge` handles 70B INT8 comfortably with batch sizes of 8-16. That means we can serve multiple users' requests concurrently. 4-bit on `g4dn` instances gives us batch size 1-4 max. We'd need to spin up way more instances to handle the same throughput, which actually costs more money, not less.

Third, latency. 8-bit has native Tensor Core support on AWS P3 and P4D instances. 4-bit requires dequantization overhead. For something as time-sensitive as real-time recommendations where users are waiting for results, 8-bit is measurably faster. We're talking 20-40ms latency difference, which matters at scale.

Finally, operational simplicity. 8-bit is battle-tested across the industry. Most SageMaker examples use it. Most monitoring tools understand it. We can put this into production confidently next week. 4-bit would require us to build custom calibration pipelines, extensive validation in staging, and more sophisticated monitoring to catch accuracy degradation. That's weeks of work.

Now, if memory was genuinely the bottleneck and we had to use 4-bit say we only had access to `g4dn` instances we'd use GPTQ with our actual recommendation logs as calibration data, run A/B tests extensively before scaling, and probably invest in QAT down the line. But given we've got AWS infrastructure available? 8-bit is the right call."

That's the answer that gets you to the next round.

## The Real Takeaway

Quantization isn't just about model size. It's about understanding the entire ecosystem your AWS hardware options, your latency requirements, your accuracy tolerance, and your cloud budget. Pick the wrong one and you're either wasting money or losing money. Maybe both.

The engineers who get hired at Amazon, Google, or Microsoft know that the technical choice isn't separate from the business choice. They're the same thing. They understand that a quantization decision is actually an infrastructure decision, which is actually a revenue decision. That's what separates the people who design systems that actually work in production from those who just know the theory.

And that's the difference between getting an offer and getting a polite "we'll be in touch."

---

For more insights on GenAI engineering, AWS deployment, interviews at tech companies, and what it actually takes to deploy LLMs at scale, check out Gnanesh Balusa's blog.

 
Published on November 6, 2025 at 8:30 PM IST [RSS feed]({{ "/feed.xml" | relative_url }}){:target="_blank"}.
