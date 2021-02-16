Require Import Rupicola.Lib.Core.
Require Import Rupicola.Lib.Notations.
Require Export Rupicola.Lib.Gensym.
Require Import Rupicola.Lib.Tactics.

Section with_parameters.
  Context {semantics : Semantics.parameters}
          {semantics_ok : Semantics.parameters_ok _}.

  Lemma compile_dlet_as_nlet_eq {tr mem locals functions} {A} {vars: list string} (v: A):
    forall {T} {pred: T -> predicate} {k: A -> T}
      cmd,
      <{ Trace := tr;
         Memory := mem;
         Locals := locals;
         Functions := functions }>
      cmd
      <{ pred (nlet_eq (P := fun _ => T) vars v (fun x _ => k x)) }> ->
      <{ Trace := tr;
         Memory := mem;
         Locals := locals;
         Functions := functions }>
      cmd
      <{ pred (dlet v k) }>.
  Proof. intros; assumption. Qed.

  Lemma compile_nlet_as_nlet_eq {tr mem locals functions} {A} (v: A):
    forall {T} {pred: T -> predicate} {k: A -> T}
      vars cmd,
      <{ Trace := tr;
         Memory := mem;
         Locals := locals;
         Functions := functions }>
      cmd
      <{ pred (nlet_eq (P := fun _ => T) vars v (fun x _ => k x)) }> ->
      <{ Trace := tr;
         Memory := mem;
         Locals := locals;
         Functions := functions }>
      cmd
      <{ pred (nlet vars v k) }>.
  Proof. intros; assumption. Qed.

  Lemma compile_skip {tr mem locals functions} {pred0: predicate} :
    pred0 tr mem locals ->
    (<{ Trace := tr;
        Memory := mem;
        Locals := locals;
        Functions := functions }>
     cmd.skip
     <{ pred0 }>).
  Proof. repeat straightline; assumption. Qed.

  Lemma compile_seq {tr mem locals functions} :
    forall {pred0 pred1: predicate} {c0 c1},
      (<{ Trace := tr;
          Memory := mem;
          Locals := locals;
          Functions := functions }>
       c0
       <{ pred0 }>) ->
      (forall tr mem locals,
         pred0 tr mem locals ->
       <{ Trace := tr;
          Memory := mem;
          Locals := locals;
          Functions := functions }>
       c1
       <{ pred1 }>) ->
      <{ Trace := tr;
         Memory := mem;
         Locals := locals;
         Functions := functions }>
      cmd.seq c0 c1
      <{ pred1 }>.
  Proof. intros; eapply WeakestPrecondition_weaken; eauto. Qed.

  Lemma compile_word_of_Z_constant {tr mem locals functions} (z: Z) :
    let v := word.of_Z z in
    forall {P} {pred: P v -> predicate}
      {k: nlet_eq_k P v} {k_impl}
      var,
      (let v := v in
       <{ Trace := tr;
          Memory := mem;
          Locals := map.put locals var v;
          Functions := functions }>
       k_impl
       <{ pred (k v eq_refl) }>) ->
      <{ Trace := tr;
         Memory := mem;
         Locals := locals;
         Functions := functions }>
      cmd.seq (cmd.set var (expr.literal z)) k_impl
      <{ pred (nlet_eq [var] v k) }>.
  Proof. repeat straightline; eassumption. Qed.

  Lemma compile_word_constant {tr mem locals functions} (w: word) :
    forall {P} {pred: P w -> predicate}
      {k: nlet_eq_k P w} {k_impl}
      var,
      <{ Trace := tr;
         Memory := mem;
         Locals := map.put locals var w;
         Functions := functions }>
      k_impl
      <{ pred (k w eq_refl) }> ->
      <{ Trace := tr;
         Memory := mem;
         Locals := locals;
         Functions := functions }>
      cmd.seq (cmd.set var (expr.literal (word.unsigned w))) k_impl
      <{ pred (nlet_eq [var] w k) }>.
  Proof. repeat straightline; subst_lets_in_goal; rewrite word.of_Z_unsigned; eauto. Qed.

  Lemma compile_Z_constant {tr mem locals functions} z :
    let v := z in
    forall {P} {pred: P v -> predicate}
      {k: nlet_eq_k P v} {k_impl}
      var,
      (let v := v in
       <{ Trace := tr;
          Memory := mem;
          Locals := map.put locals var (word.of_Z v);
          Functions := functions }>
       k_impl
       <{ pred (k v eq_refl) }>) ->
      <{ Trace := tr;
         Memory := mem;
         Locals := locals;
         Functions := functions }>
      cmd.seq (cmd.set var (expr.literal z)) k_impl
      <{ pred (nlet_eq [var] v k) }>.
  Proof. repeat straightline; eassumption. Qed.

  Lemma compile_nat_constant {tr mem locals functions} n :
    let v := n in
    forall {P} {pred: P v -> predicate}
      {k: nlet_eq_k P v} {k_impl}
      var,
      (let v := v in
       <{ Trace := tr;
          Memory := mem;
          Locals := map.put locals var (word.of_Z (Z.of_nat v));
          Functions := functions }>
       k_impl
       <{ pred (k v eq_refl) }>) ->
      <{ Trace := tr;
         Memory := mem;
         Locals := locals;
         Functions := functions }>
      cmd.seq (cmd.set var (expr.literal (Z.of_nat n))) k_impl
      <{ pred (nlet_eq [var] v k) }>.
  Proof. repeat straightline; eassumption. Qed.

  Notation b2w b :=
    (word.of_Z (Z.b2z b)).

  Lemma b2w_inj:
    forall b1 b2, b2w b1 = b2w b2 -> b1 = b2.
  Proof.
    intros [|] [|]; simpl;
      intros H%(f_equal word.unsigned);
      rewrite ?word.unsigned_of_Z_0, ?word.unsigned_of_Z_1 in H;
      cbn; congruence.
  Qed.

  Lemma compile_bool_constant {tr mem locals functions} b :
    let v := b in
    forall {P} {pred: P v -> predicate}
      {k: nlet_eq_k P v} {k_impl}
      var,
      (let v := v in
       <{ Trace := tr;
          Memory := mem;
          Locals := map.put locals var (b2w v);
          Functions := functions }>
       k_impl
       <{ pred (k v eq_refl) }>) ->
      <{ Trace := tr;
         Memory := mem;
         Locals := locals;
         Functions := functions }>
      cmd.seq (cmd.set var (expr.literal (Z.b2z v))) k_impl
      <{ pred (nlet_eq [var] v k) }>.
  Proof. repeat straightline; eassumption. Qed.

  Lemma compile_binop_xxx {T} T2w op f
        (H: forall x y: T, T2w (f x y) = Semantics.interp_binop op (T2w x) (T2w y))
        {tr mem locals functions} (x y: T) :
    let v := f x y in
    forall {P} {pred: P v -> predicate}
      {k: nlet_eq_k P v} {k_impl}
      x_var y_var var,
      map.get locals x_var = Some (T2w x) ->
      map.get locals y_var = Some (T2w y) ->
      (let v := v in
       <{ Trace := tr;
          Memory := mem;
          Locals := map.put locals var (T2w v);
          Functions := functions }>
       k_impl
       <{ pred (k v eq_refl) }>) ->
      <{ Trace := tr;
         Memory := mem;
         Locals := locals;
         Functions := functions }>
      cmd.seq (cmd.set var (expr.op op (expr.var x_var) (expr.var y_var)))
              k_impl
      <{ pred (nlet_eq [var] v k) }>.
  Proof. repeat (eexists; split; eauto). Qed.

  Notation unfold_id term :=
    ltac:(let tm := fresh in pose term as tm;
          change (id ?x) with x in (type of tm);
          let t := type of tm in
          exact (tm: t)) (only parsing).

  Definition compile_word_add :=
    unfold_id (@compile_binop_xxx _ id bopname.add word.add ltac:(reflexivity)).
  Definition compile_word_sub :=
    unfold_id (@compile_binop_xxx _ id bopname.sub word.sub ltac:(reflexivity)).
  Definition compile_word_mul :=
    unfold_id (@compile_binop_xxx _ id bopname.mul word.mul ltac:(reflexivity)).
  Definition compile_word_mulhuu :=
    unfold_id (@compile_binop_xxx _ id bopname.mulhuu word.mulhuu ltac:(reflexivity)).
  Definition compile_word_divu :=
    unfold_id (@compile_binop_xxx _ id bopname.divu word.divu ltac:(reflexivity)).
  Definition compile_word_remu :=
    unfold_id (@compile_binop_xxx _ id bopname.remu word.modu ltac:(reflexivity)).
  Definition compile_word_and :=
    unfold_id (@compile_binop_xxx _ id bopname.and word.and ltac:(reflexivity)).
  Definition compile_word_or :=
    unfold_id (@compile_binop_xxx _ id bopname.or word.or ltac:(reflexivity)).
  Definition compile_word_xor :=
    unfold_id (@compile_binop_xxx _ id bopname.xor word.xor ltac:(reflexivity)).
  (* Definition compile_word_ndn :=
     unfold_id (@compile_binop_xxx _ id bopname.ndn word.xor ltac:(reflexivity)). *)
  Definition compile_word_sru :=
    unfold_id (@compile_binop_xxx _ id bopname.sru word.sru ltac:(reflexivity)).
  Definition compile_word_slu :=
    unfold_id (@compile_binop_xxx _ id bopname.slu word.slu ltac:(reflexivity)).
  Definition compile_word_srs :=
    unfold_id (@compile_binop_xxx _ id bopname.srs word.srs ltac:(reflexivity)).

  Ltac compile_binop_zzw_bitwise lemma :=
    intros; cbn;
    apply word.unsigned_inj;
    rewrite lemma, !word.unsigned_of_Z;
    bitblast.Z.bitblast;
    rewrite !word.testbit_wrap;
    bitblast.Z.bitblast_core.

  Definition compile_Z_add :=
    @compile_binop_xxx _ word.of_Z bopname.add Z.add word.ring_morph_add.
  Definition compile_Z_sub :=
    @compile_binop_xxx _ word.of_Z bopname.sub Z.sub word.ring_morph_sub.
  Definition compile_Z_mul :=
    @compile_binop_xxx _ word.of_Z bopname.mul Z.mul word.ring_morph_mul.
  Definition compile_Z_and :=
    @compile_binop_xxx _ word.of_Z bopname.and Z.land
                       ltac:(compile_binop_zzw_bitwise word.unsigned_and_nowrap).
  Definition compile_Z_or :=
    @compile_binop_xxx _ word.of_Z bopname.or Z.lor
                       ltac:(compile_binop_zzw_bitwise word.unsigned_or_nowrap).
  Definition compile_Z_xor :=
    @compile_binop_xxx _ word.of_Z bopname.xor Z.lxor
                       ltac:(compile_binop_zzw_bitwise word.unsigned_xor_nowrap).

  Lemma compile_binop_xxb {T} T2w op (f: T -> T -> bool)
        (H: forall x y, b2w (f x y) = Semantics.interp_binop op (T2w x) (T2w y))
        {tr mem locals functions} (x y: T) :
    let v := f x y in
    forall {P} {pred: P v -> predicate}
      {k: nlet_eq_k P v} {k_impl}
      x_var y_var var,
      map.get locals x_var = Some (T2w x) ->
      map.get locals y_var = Some (T2w y) ->
      (let v := v in
       <{ Trace := tr;
          Memory := mem;
          Locals := map.put locals var (b2w v);
          Functions := functions }>
       k_impl
       <{ pred (k v eq_refl) }>) ->
      <{ Trace := tr;
         Memory := mem;
         Locals := locals;
         Functions := functions }>
      cmd.seq (cmd.set var (expr.op op (expr.var x_var) (expr.var y_var)))
              k_impl
      <{ pred (nlet_eq [var] v k) }>.
  Proof. repeat (eexists; split; eauto). Qed.

  Ltac compile_binop_wwb_t :=
    unfold id; cbn; intros; destruct_one_match; reflexivity.

  Definition compile_word_lts :=
    unfold_id (@compile_binop_xxb _ id bopname.lts word.lts ltac:(compile_binop_wwb_t)).
  Definition compile_word_ltu :=
    unfold_id (@compile_binop_xxb _ id bopname.ltu word.ltu ltac:(compile_binop_wwb_t)).
  Definition compile_word_eqb :=
    unfold_id (@compile_binop_xxb _ id bopname.eq word.eqb ltac:(compile_binop_wwb_t)).

  Lemma bool_word_eq_compat {T} T2w (eqb: T -> T -> bool)
        (T2w_inj: forall x y, T2w x = T2w y -> x = y)
        (eqb_compat: forall x y, eqb x y = true <-> x = y) :
    forall x y,
      b2w (eqb x y) = (if word.eqb (T2w x) (T2w y) then word.of_Z 1 else word.of_Z 0).
  Proof.
    intros; rewrite word.unsigned_eqb.
    destruct eqb eqn:Hb; destruct Z.eqb eqn:Hz; try reflexivity.
    - apply eqb_compat in Hb; subst.
      apply Z.eqb_neq in Hz; congruence.
    - apply Z.eqb_eq, word.unsigned_inj, T2w_inj in Hz; subst.
      rewrite (proj2 (eqb_compat _ _)) in Hb; congruence.
  Qed.

  Ltac compile_binop_bbb_t lemma :=
    intros x y; cbn;
    match goal with
    | [  |- _ = ?w ] =>
      rewrite <- (word.of_Z_unsigned w);
      rewrite lemma, !word.unsigned_of_Z_b2z; destruct x, y; reflexivity
    end.

  Notation cbv_beta_b2w x :=
    ltac:(pose proof x as x0;
         change ((fun b => b2w b) ?y) with (b2w y) in (type of x0);
         let t := type of x0 in exact (x: t)) (only parsing).

  Definition compile_bool_eqb :=
    cbv_beta_b2w (@compile_binop_xxb
                    _ (fun x => b2w x) bopname.eq Bool.eqb
                    (bool_word_eq_compat (fun w => b2w w) _ b2w_inj Bool.eqb_true_iff)).

  (* FIXME add comparisons on bytes *)

  Definition compile_bool_andb :=
    cbv_beta_b2w (@compile_binop_xxb _ (fun x => b2w x) bopname.and andb
                                     ltac:(compile_binop_bbb_t word.unsigned_and_nowrap)).
  Definition compile_bool_orb :=
    cbv_beta_b2w (@compile_binop_xxb _ (fun x => b2w x) bopname.or orb
                                     ltac:(compile_binop_bbb_t word.unsigned_or_nowrap)).
  Definition compile_bool_xorb :=
    cbv_beta_b2w (@compile_binop_xxb _ (fun x => b2w x) bopname.xor xorb
                                     ltac:(compile_binop_bbb_t word.unsigned_xor_nowrap)).

  (* TODO: deduplicate and automate *)
  Lemma compile_copy_word {tr mem locals functions} v0 :
    let v := v0 in
    forall {P} {pred: P v -> predicate}
      {k: nlet_eq_k P v} {k_impl}
      src_var dst_var,
      map.get locals src_var = Some v0 ->
      (let v := v in
       <{ Trace := tr;
          Memory := mem;
          Locals := map.put locals dst_var v;
          Functions := functions }>
       k_impl
       <{ pred (k v eq_refl) }>) ->
      <{ Trace := tr;
         Memory := mem;
         Locals := locals;
         Functions := functions }>
      cmd.seq (cmd.set dst_var (expr.var src_var)) k_impl
      <{ pred (nlet_eq [dst_var] v k) }>.
  Proof.
    repeat straightline'; eauto.
  Qed.

  Lemma compile_copy_byte {tr mem locals functions} (b: byte) :
    let v := b in
    forall {P} {pred: P v -> predicate}
      {k: nlet_eq_k P v} {k_impl}
      src_var dst_var,
      map.get locals src_var = Some (word_of_byte b) ->
      (let v := v in
       <{ Trace := tr;
          Memory := mem;
          Locals := map.put locals dst_var (word_of_byte v);
          Functions := functions }>
       k_impl
       <{ pred (k v eq_refl) }>) ->
      <{ Trace := tr;
         Memory := mem;
         Locals := locals;
         Functions := functions }>
      cmd.seq (cmd.set dst_var (expr.var src_var)) k_impl
      <{ pred (nlet_eq [dst_var] v k) }>.
  Proof.
    repeat straightline'; eauto.
  Qed.

  (* FIXME find a way to automate the application of these copy lemmas *)
  (* N.B. should only be added to compilation tactics that solve their subgoals,
     since this applies to any shape of goal *)
  Lemma compile_copy_pointer {tr mem locals functions} {data} (x: data) :
    let v := x in
    forall {P} {pred: P v -> predicate}
      {k: nlet_eq_k P v} {k_impl}
      (Data : Semantics.word -> data -> Semantics.mem -> Prop) R
      x_var x_ptr var,

      (* This assumption is used to drive the compiler, but it's not used by the proof *)
      (Data x_ptr x * R)%sep mem ->
      map.get locals x_var = Some x_ptr ->

      (let v := v in
       <{ Trace := tr;
          Memory := mem;
          Locals := map.put locals var x_ptr;
          Functions := functions }>
       k_impl
       <{ pred (k v eq_refl) }>) ->
      <{ Trace := tr;
         Memory := mem;
         Locals := locals;
         Functions := functions }>
      cmd.seq (cmd.set var (expr.var x_var)) k_impl
      <{ pred (nlet_eq [var] v k) }>.
  Proof.
    intros.
    repeat straightline'.
    eassumption.
  Qed.

  Lemma compile_sig_as_nlet_eq {tr mem locals functions} {A} P0 (x0: A) Px0:
    let v := exist P0 x0 Px0 in
    forall {T} {pred: T -> predicate} {k: {x: A | P0 x} -> T}
      vars cmd,
      (let Px := Px0 in
       let cast {x0'} Heq := eq_rect_r (fun x => P0 x) Px Heq in
       <{ Trace := tr;
          Memory := mem;
          Locals := locals;
          Functions := functions }>
       cmd
       <{ pred (nlet_eq (P := fun _ => T) vars x0
                        (fun x0' Heq => k (exist P0 x0' (cast Heq)))) }>) ->
      <{ Trace := tr;
         Memory := mem;
         Locals := locals;
         Functions := functions }>
      cmd
      <{ pred (nlet vars v k) }>.
  Proof. eauto. Qed.

  (* N.B. this should *not* be added to any compilation tactics, since it will
     always apply; it needs to be applied manually *)
  Lemma compile_unset {tr mem locals functions} :
    forall {pred0: predicate}
      var cmd,
      <{ Trace := tr;
         Memory := mem;
         Locals := map.remove locals var;
         Functions := functions }>
      cmd
      <{ pred0 }> ->
      <{ Trace := tr;
         Memory := mem;
         Locals := locals;
         Functions := functions }>
      cmd.seq (cmd.unset var) cmd
      <{ pred0 }>.
  Proof.
    repeat straightline'; eauto.
  Qed.

  Definition DefaultValue (T: Type) (t: T) := T.

  Lemma compile_unsets {tr mem locals functions}
        {pred0: predicate} :
    forall (vars: DefaultValue (list string) []) cmd,
      (<{ Trace := tr;
          Memory := mem;
          Locals := map.remove_many locals vars;
          Functions := functions }>
       cmd
       <{ pred0 }>) ->
      (<{ Trace := tr;
          Memory := mem;
          Locals := locals;
          Functions := functions }>
       fold_right (fun v c => cmd.seq (cmd.unset v) c) cmd vars
       <{ pred0 }>).
  Proof.
    induction vars in locals |- *; cbn [fold_right]; intros.
    - assumption.
    - apply compile_unset.
      apply IHvars.
      assumption.
  Qed.

  Lemma compile_if {tr mem locals functions} (c: bool) {A} (t f: A) :
    let v := if c then t else f in
    forall {P} {pred: P v -> predicate} {val_pred: A -> predicate}
      {k: nlet_eq_k P v} {k_impl t_impl f_impl}
      c_var vars,

      map.get locals c_var = Some (b2w c) ->

      (let v := v in
       c = true ->
       <{ Trace := tr;
          Memory := mem;
          Locals := locals;
          Functions := functions }>
       t_impl
       <{ val_pred t }>) ->
      (let v := v in
       c = false ->
       <{ Trace := tr;
          Memory := mem;
          Locals := locals;
          Functions := functions }>
       f_impl
       <{ val_pred f }>) ->
      (let v := v in
       forall tr mem locals,
         val_pred v tr mem locals ->
       <{ Trace := tr;
          Memory := mem;
          Locals := locals;
          Functions := functions }>
       k_impl
       <{ pred (k v eq_refl) }>) ->
      <{ Trace := tr;
         Memory := mem;
         Locals := locals;
         Functions := functions }>
      cmd.seq
        (cmd.cond (expr.var c_var) t_impl f_impl)
        k_impl
      <{ pred (nlet_eq vars v k) }>.
  Proof.
    intros * Hc Ht Hf Hk.
    repeat straightline'.
    split_if ltac:(repeat straightline'); subst_lets_in_goal.
    all: rewrite word.unsigned_of_Z_b2z; cbv [Z.b2z].
    all: destruct_one_match; try congruence; [ ]; intros.
    all: eapply compile_seq; eauto.
  Qed.

  Section NoSkips.
    Definition is_skip cmd :=
      match cmd with
      | cmd.skip => true
      | _ => false
      end.

    Lemma is_skip_sound cmd :
      is_skip cmd = true -> cmd = cmd.skip.
    Proof. destruct cmd; inversion 1; congruence. Qed.

    Lemma is_skip_complete cmd :
      is_skip cmd = false -> cmd <> cmd.skip.
    Proof. destruct cmd; inversion 1; congruence. Qed.

    Fixpoint noskips (c: cmd.cmd) :=
      match c with
      | cmd.stackalloc lhs nbytes body =>
        cmd.stackalloc lhs nbytes (noskips body)
      | cmd.cond condition nonzero_branch zero_branch =>
        cmd.cond condition (noskips nonzero_branch) (noskips zero_branch)
      | cmd.seq s1 s2 =>
        let s1 := noskips s1 in
        let s2 := noskips s2 in
        match is_skip s1, is_skip s2 with
        | true, _ => s2
        | _, true => s1
        | _, _ => cmd.seq s1 s2
        end
      | cmd.while test body => cmd.while test (noskips body)
      | _ => c
      end.

    Lemma noskips_correct:
      forall cmd {tr mem locals functions} post,
        WeakestPrecondition.program functions
          (noskips cmd) tr mem locals post <->
        WeakestPrecondition.program functions
          cmd tr mem locals post.
    Proof.
      split; revert tr mem locals post.
      all: induction cmd;
        repeat match goal with
               | _ => eassumption
               | _ => apply IHcmd
               | [ H: _ /\ _ |- _ ] => destruct H
               | [  |- _ /\ _ ] => split
               | [ H: forall v t m l, ?P v t m l -> exists _, _ |- ?P _ _ _ _ -> _ ] =>
                 let h := fresh in intros h; specialize (H _ _ _ _ h)
               | [ H: exists _, _ |- _ ] => destruct H
               | [  |- exists _, _ ] => eexists
               | [ H: context[WeakestPrecondition.cmd] |- context[WeakestPrecondition.cmd] ] => solve [eapply H; eauto]
               | _ => unfold WeakestPrecondition.program in * || cbn || intros ? || eauto
               end.

      all: destruct (is_skip (noskips cmd1)) eqn:H1;
        [ apply is_skip_sound in H1; rewrite H1 in * |
          apply is_skip_complete in H1;
           (destruct (is_skip (noskips cmd2)) eqn:H2;
            [ apply is_skip_sound in H2; rewrite H2 in * |
              apply is_skip_complete in H2 ]) ].

      - apply IHcmd1, IHcmd2; eassumption.
      - eapply WeakestPrecondition_weaken, IHcmd1; eauto.
      - eapply WeakestPrecondition_weaken.
        * intros * H0. eapply IHcmd2. apply H0.
        * eapply IHcmd1. eassumption.

      - eapply IHcmd1 in H. eapply IHcmd2. eassumption.
      - eapply IHcmd1 in H. eapply WeakestPrecondition_weaken in H; [ apply H |].
        intros; eapply IHcmd2; eauto.
      - apply IHcmd1 in H. eapply WeakestPrecondition_weaken in H; [ apply H |].
        intros * H0%IHcmd2. apply H0.
    Qed.

    Definition compile_setup_remove_skips := noskips_correct.
  End NoSkips.

  Section Setup.
    Definition wp_bind_retvars retvars (P: list word -> predicate) :=
      fun tr mem locals =>
        exists ws, map.getmany_of_list locals retvars = Some ws /\
              P ws tr mem locals.

    Lemma compile_setup_getmany_list_map {tr mem locals functions} :
      forall P {cmd} retvars,
        <{ Trace := tr;
           Memory := mem;
           Locals := locals;
           Functions := functions }>
        cmd
        <{ wp_bind_retvars retvars P }> ->
        <{ Trace := tr;
           Memory := mem;
           Locals := locals;
           Functions := functions }>
        cmd
        <{ fun tr' mem' locals' =>
             WeakestPrecondition.list_map
               (WeakestPrecondition.get locals') retvars
               (fun ws => P ws tr' mem' locals') }>.
    Proof.
      intros; eapply WeakestPrecondition_weaken; try eassumption.
      clear; firstorder eauto using getmany_list_map.
    Qed.

    Lemma compile_setup_WeakestPrecondition_call_first {tr mem locals}
          name argnames retvars body args functions post:
      map.of_list_zip argnames args = Some locals ->
      <{ Trace := tr;
         Memory := mem;
         Locals := locals;
         Functions := functions }>
      body
      <{ wp_bind_retvars
           retvars
           (fun rets tr' mem' local' => post tr' mem' rets)  }> ->
      WeakestPrecondition.call
        ((name, (argnames, retvars, body)) :: functions)
        name tr mem args post.
    Proof.
      intros; WeakestPrecondition.unfold1_call_goal.
      red. rewrite String.eqb_refl.
      red. eexists; split; eauto.
      eapply WeakestPrecondition_weaken; try eassumption.
      clear; firstorder eauto using getmany_list_map.
    Qed.

    Lemma compile_setup_postcondition_func_noret
          {T} spec (x: T) cmd R tr mem locals functions :
      (let pred a := postcondition_cmd (fun _ : Semantics.locals => True) (spec a) [] R tr in
       <{ Trace := tr;
          Memory := mem;
          Locals := locals;
          Functions := functions }>
       cmd
       <{ pred x }>) ->
      <{ Trace := tr;
         Memory := mem;
         Locals := locals;
         Functions := functions }>
      cmd
      <{ wp_bind_retvars
           []
           (fun rets tr' m' _ =>
              postcondition_func_norets (spec x) R tr tr' m' rets) }>.
    Proof.
      cbv [postcondition_func_norets
             postcondition_func postcondition_cmd]; intros.
      use_hyp_with_matching_cmd;
        cbn in *; intros; exists []; sepsimpl; subst; eauto.
    Qed.

    Lemma compile_setup_postcondition_func
          {T} spec (x: T) cmd R tr mem locals retvars functions :
      (let pred a := postcondition_cmd (fun _ : Semantics.locals => True) (spec a) retvars R tr in
       <{ Trace := tr;
          Memory := mem;
          Locals := locals;
          Functions := functions }>
       cmd
       <{ pred x }>) ->
      <{ Trace := tr;
         Memory := mem;
         Locals := locals;
         Functions := functions }>
      cmd
      <{ wp_bind_retvars
           retvars
           (fun rets tr' m' _ => postcondition_func (spec x) R tr tr' m' rets) }>.
    Proof.
      cbv [postcondition_func postcondition_cmd]; intros.
      use_hyp_with_matching_cmd; red; sepsimpl; subst; eauto.
    Qed.
  End Setup.
End with_parameters.

Ltac compile_find_post :=
  lazymatch goal with
  | |- WeakestPrecondition.cmd _ _ _ _ _ (?pred ?term) =>
    constr:((pred, term))
  end.

Ltac compile_setup_unfold_spec_of :=
  intros;
  match goal with
  | [  |- ?g ] =>
    let hd := term_head g in
    match type of hd with
    | spec_of _ => cbv [hd]; intros
    end
  | _ => idtac (* Spec inlined *)
  end.

Ltac compile_setup_find_app term head :=
  match constr:(Set) with
  | _ => find_app term head
  | _ => fail "Gallina program" head "not found in postcondition" term
  end.

Definition __rupicola_program_marker {A} (a: A) := True.

Ltac compile_setup_isolate_gallina_program :=
  lazymatch goal with
  | [ _: __rupicola_program_marker ?prog |-
      WeakestPrecondition.cmd _ _ _ _ _ ?post ] =>
    let gallina := compile_setup_find_app post prog in
    lazymatch (eval pattern gallina in post) with
    | ?pred ?gallina =>
      let nm := fresh "pred" in
      set pred as nm; change post with (nm gallina)
    end
  | |- WeakestPrecondition.cmd _ _ _ _ _ (?pred ?spec) => idtac
  | _ => fail "Not sure which program is being compiled.  Expecting a WeakestPrecondition goal with a postcondition in the form (?pred gallina_spec)."
  end.

Ltac compile_setup_unfold_gallina_spec :=
  match compile_find_post with
  | (_, ?spec) => let hd := term_head spec in unfold hd
  end.

Create HintDb compiler_setup discriminated.
Hint Resolve compile_setup_postcondition_func : compiler_setup.
Hint Resolve compile_setup_postcondition_func_noret : compiler_setup.
Hint Extern 20 (WeakestPrecondition.cmd _ _ _ _ _ _) => intros; shelve : compiler_setup.

Ltac compile_setup :=
  cbv [program_logic_goal_for];
  compile_setup_unfold_spec_of;
  eapply compile_setup_WeakestPrecondition_call_first;
  [ try reflexivity (* Arity check *)
  | first [progress unshelve (typeclasses eauto with compiler_setup) |
           compile_setup_isolate_gallina_program]; intros;
    compile_setup_unfold_gallina_spec;
    apply compile_setup_remove_skips;
    unfold WeakestPrecondition.program ].

Ltac lookup_variable m val :=
  lazymatch m with
  | map.put _ ?k val => constr:(k)
  | map.put ?m' _ _ => lookup_variable m' val
  end.

Ltac map_to_list m :=
  let rec loop m acc :=
      match m with
      | map.put ?m ?k ?v =>
        loop m uconstr:((k, v) :: acc)
      | map.empty =>
        (* Reverse for compatibility with map.of_list *)
        uconstr:(List.rev acc)
      end in
  loop m uconstr:([]).

Ltac solve_map_get_goal_refl m :=
  let b := map_to_list m in
  change m with (map.of_list b);
  apply map.get_of_list;
  reflexivity.

Ltac solve_map_get_goal_step :=
  lazymatch goal with
  | [ H: map.extends ?m2 ?m1 |- map.get ?m2 ?k = Some ?v ] =>
    simple apply (fun p => @map.extends_get _ _ _ m1 m2 k v p H)
  | [  |- context[map.remove_many _ []] ] =>
    (* This comes from compile_unset with an empty list *)
    change (map.remove_many ?m []) with m
  | [  |- map.get ?m ?k = ?v ] =>
    tryif first [ has_evar k | has_evar m ] then
      match v with
      | Some ?val =>
        tryif has_evar val then fail 1 val "has evars" else
          first [ simple apply map.get_put_same | rewrite map.get_put_diff ]
      | None =>
        first [ simple apply map.get_empty | rewrite map.get_put_diff ]
      end
    else
      solve_map_get_goal_refl m
  | [  |- _ <> _ ] => congruence
  end.

Ltac solve_map_get_goal :=
  progress repeat solve_map_get_goal_step.

Ltac solve_map_remove_many_reify  :=
  lazymatch goal with
  | [  |- map.remove_many ?m0 _ = ?m1 ] =>
    let b0 := map_to_list m0 in
    let b1 := map_to_list m1 in
    change m0 with (map.of_list b0);
    change m1 with (map.of_list b1)
  end.

Ltac solve_map_remove_many :=
  solve_map_remove_many_reify;
  apply map.remove_many_diff;
  [ try (vm_compute; reflexivity) | try reflexivity ].

Create HintDb compiler_cleanup discriminated.
Hint Unfold wp_bind_retvars : compiler_cleanup.
Hint Unfold postcondition_cmd : compiler_cleanup.

Class IsRupicolaBinding {T} (t: T) := is_rupicola_binding: bool.
Hint Extern 2 (IsRupicolaBinding (nlet _ _ _)) => exact true : typeclass_instances.
Hint Extern 2 (IsRupicolaBinding (nlet_eq _ _ _)) => exact true : typeclass_instances.
Hint Extern 2 (IsRupicolaBinding (dlet _ _)) => exact true : typeclass_instances.
Hint Extern 5 (IsRupicolaBinding _) => exact false : typeclass_instances.

Ltac is_rupicola_binding term :=
  constr:(match tt return IsRupicolaBinding term with _ => _ end).

Ltac compile_unfold_head_binder' hd :=
  (** Use `compile_unfold_head_binding` for debugging **)
  lazymatch compile_find_post with
  | (?pred, ?x0) => (* FIXME should just unfold x in all cases that report isunifiable, but that does too much *)
    lazymatch goal with
    | [  |- context C [pred x0] ] =>
      match is_rupicola_binding x0 with
      | true =>
        let x0 := unfold_head x0 in
        let C' := context C [pred x0] in
        change C'
      | false => fail 0 x0 "does not look like a let-binding"
      end
    end
  end.

(* Useful for debugging *)
Ltac compile_unfold_head_binder :=
  let p := compile_find_post in
  compile_unfold_head_binder' p.

Create HintDb compiler.
Hint Extern 1 => simple eapply compile_word_constant; shelve : compiler.
Hint Extern 1 => simple eapply compile_word_of_Z_constant; shelve : compiler.
Hint Extern 1 => simple eapply compile_Z_constant; shelve : compiler.
Hint Extern 1 => simple eapply compile_nat_constant; shelve : compiler.
Hint Extern 1 => simple eapply compile_bool_constant; shelve : compiler.
Hint Extern 1 => simple eapply compile_word_add; shelve : compiler.
Hint Extern 1 => simple eapply compile_word_sub; shelve : compiler.
Hint Extern 1 => simple eapply compile_word_mul; shelve : compiler.
Hint Extern 1 => simple eapply compile_word_mulhuu; shelve : compiler.
Hint Extern 1 => simple eapply compile_word_divu; shelve : compiler.
Hint Extern 1 => simple eapply compile_word_remu; shelve : compiler.
Hint Extern 1 => simple eapply compile_word_and; shelve : compiler.
Hint Extern 1 => simple eapply compile_word_or; shelve : compiler.
Hint Extern 1 => simple eapply compile_word_xor; shelve : compiler.
Hint Extern 1 => simple eapply compile_word_sru; shelve : compiler.
Hint Extern 1 => simple eapply compile_word_slu; shelve : compiler.
Hint Extern 1 => simple eapply compile_word_srs; shelve : compiler.
Hint Extern 1 => simple eapply compile_Z_add; shelve : compiler.
Hint Extern 1 => simple eapply compile_Z_sub; shelve : compiler.
Hint Extern 1 => simple eapply compile_Z_mul; shelve : compiler.
Hint Extern 1 => simple eapply compile_Z_and; shelve : compiler.
Hint Extern 1 => simple eapply compile_Z_or; shelve : compiler.
Hint Extern 1 => simple eapply compile_Z_xor; shelve : compiler.
Hint Extern 1 => simple eapply compile_word_lts; shelve : compiler.
Hint Extern 1 => simple eapply compile_word_ltu; shelve : compiler.
Hint Extern 1 => simple eapply compile_word_eqb; shelve : compiler.
Hint Extern 1 => simple eapply compile_bool_eqb; shelve : compiler.
Hint Extern 1 => simple eapply compile_bool_andb; shelve : compiler.
Hint Extern 1 => simple eapply compile_bool_orb; shelve : compiler.
Hint Extern 1 => simple eapply compile_bool_xorb; shelve : compiler.

Ltac compile_binding :=
  (* We don't want to show users goals with nlet_eq, so compile_nlet_as_nlet_eq
     isn't in the ‘compiler’ hint db. *)
  try simple apply compile_nlet_as_nlet_eq;
  progress unshelve (typeclasses eauto 3 with compiler); shelve_unifiable.

(* Use [simple eapply] (not eapply) if you add anything here, to ensure that Coq
   doesn't peek past the first [nlet]. *)
Ltac compile_custom := fail.

Ltac compile_cleanup :=
  match goal with
  | [ H: _ /\ _ |- _ ] => destruct H
  | [ H: ?x = _ |- _ ] => is_var x; subst x
  | [ H: match ?x with _ => _ end |- _ ] => destruct x; [ idtac ]
  | [  |- let _ := _ in _ ] => intros
  | [  |- forall _, _ ] => intros
  end.

Ltac compile_cleanup_post :=
  match goal with
  | _ => compile_cleanup
  | [  |- True ] => exact I
  | [  |- _ /\ _ ] => split
  | [  |- _ = _ ] => reflexivity
  | [  |- exists _, _ ] => eexists
  | _ =>
    first [ progress subst_lets_in_goal
          | progress repeat autounfold with compiler_cleanup ]
  end.

Ltac compile_unset_and_skip :=
  (* [unshelve] captures the list of variables to unset as a separate goal; it
     is resolved by unification or by compile_use_default_value. *)
  unshelve refine (compile_unsets _ _ _);  (* coq#13839 *)
  [ shelve (* cmd *) | intros (* vars *) | ]; cycle 1;
  [ (* triple *)
    simple apply compile_skip;
    repeat compile_cleanup_post | ].

Ltac compile_use_default_value :=
  lazymatch goal with
  | [ |- DefaultValue ?T ?t ] => exact t
  end.

Ltac compile_solve_side_conditions :=
  match goal with
  | [  |- sep _ _ _ ] =>
    repeat autounfold with compiler_cleanup in *;
      cbn [fst snd] in *;       (* FIXME generalize this? *)
      ecancel_assumption
  | [  |- map.get _ _ = _ ] =>
    solve [subst_lets_in_goal; solve_map_get_goal]
  | [  |- map.getmany_of_list _ _ = _ ] =>
    apply map.getmany_of_list_cons
  | [  |- map.remove_many _ _ = _ ] =>
    solve_map_remove_many
  | [  |- _ <> _ ] => congruence
  | _ =>
    first [ compile_cleanup
          | solve [eauto with compiler_cleanup]
          | compile_use_default_value ]
  end.

Ltac compile_triple :=
  lazymatch compile_find_post with
  | (_, ?hd) =>
    try clear_old_seps;
    (* Look for a binding: if there is none, finish compiling *)
    match is_rupicola_binding hd with
    | true => first [compile_custom | compile_binding]
    | false => compile_unset_and_skip
    end
  end.

Ltac compile_step :=
  first [ compile_cleanup |
          compile_triple |
          compile_solve_side_conditions ].

Ltac compile_done :=
  match goal with
  | _ =>
    idtac "Compilation incomplete.";
    idtac "You may need to add new compilation lemmas using `Hint Extern 1 => simple eapply … : compiler` or to tell Rupicola about your custom bindings using `Hint Extern 2 (IsRupicolaBinding (xlet _ _ _)) => exact true : typeclass_instances`."
  end.

(* only apply compile_step when repeat_compile_step solves all the side
     conditions but one *)
Ltac safe_compile_step :=        (* TODO try to change compile_step so that it's always safe? *)
  compile_step; [ solve [repeat compile_step] .. | ].

(* TODO find the way to preserve the name of the binder in ‘k’ instead of renaming everything to ‘v’ *)

Ltac compile :=
  (* There are two repeats here because after compile_unsets we might try to
     solve some goals, fail, decide to unify the list of variables to unset with
     [], and at that point we want to try again. *)
  compile_setup; repeat repeat compile_step; compile_done.
